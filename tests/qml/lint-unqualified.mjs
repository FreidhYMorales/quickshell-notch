import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// qmllint reports an id or an import alias the file does not have as
// "Unqualified access". The smoke run never loads the lock (it would lock the
// session), so a missing `import ... as X` there only shows up as a runtime
// ReferenceError on the live session; this catches it in the one directory
// nothing else loads.
const root = fileURLToPath(new URL("../..", import.meta.url));
const shell = join(root, "shell", "lock");
const qmllint = process.env.QMLLINT ||
  join(process.env.QT_BIN || "/usr/lib/qt6/bin", "qmllint");

function walk(dir) {
  const files = [];
  const dirs = [];
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) dirs.push(path);
    else if (entry.endsWith(".qml")) files.push(path);
  }
  return { files, dirs };
}

function collect(dir) {
  const { files, dirs } = walk(dir);
  const found = { files: [...files], qmlDirs: [] };
  if (existsSync(join(dir, "qmldir"))) found.qmlDirs.push(dir);
  for (const child of dirs) {
    const nested = collect(child);
    found.files.push(...nested.files);
    found.qmlDirs.push(...nested.qmlDirs);
  }
  return found;
}

test("every lock QML file resolves the ids and import aliases it uses", () => {
  assert.ok(existsSync(qmllint), `qmllint not found at ${qmllint}`);
  const found = collect(shell);
  const args = ["-I", "/usr/lib/qt6/qml"];
  for (const dir of found.qmlDirs) args.push("-i", dir);
  args.push(...found.files);
  const result = spawnSync(qmllint, args, {
    encoding: "utf8",
    timeout: 120000,
  });
  const output = result.stdout + result.stderr;
  const unqualified = output.split("\n").filter((line) =>
    line.includes("Unqualified access")
  );
  assert.deepEqual(
    unqualified,
    [],
    "qmllint reports ids or aliases these files do not have:\n" +
      unqualified.join("\n"),
  );
});
