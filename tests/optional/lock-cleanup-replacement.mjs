import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("preserves a replacement runtime on prerequisite failure", () => {
  const parent = mkdtempSync(join(tmpdir(), "notch-cleanup-swap-"));
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    writeFileSync(
      join(parent, "pkg-config"),
      `#!${process.execPath}
const fs = require("node:fs");
const path = require("node:path");
const name = fs.readdirSync(process.env.TMPDIR).find(
  (entry) => entry.startsWith("notch-lock-isolated-"),
);
const runtime = path.join(process.env.TMPDIR, name);
fs.renameSync(runtime, runtime + ".original");
fs.mkdirSync(runtime, { mode: 0o700 });
fs.writeFileSync(path.join(runtime, "sentinel"), "keep");
process.exit(1);
`,
      { mode: 0o755 },
    );
    const result = spawnSync(process.execPath, [runner], {
      env: { PATH: parent, TMPDIR: parent },
      encoding: "utf8",
      timeout: 3000,
    });
    assert.notEqual(result.status, 0);
    const replacement = readdirSync(parent).find((name) =>
      name.startsWith("notch-lock-isolated-") && !name.endsWith(".original")
    );
    assert.ok(replacement, "replacement runtime was removed");
    assert.equal(
      readFileSync(join(parent, replacement, "sentinel"), "utf8"),
      "keep",
    );
  } finally {
    rmSync(parent, { recursive: true, force: true });
  }
});
