import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("rejects a runtime directory made accessible to other users", () => {
  const parent = mkdtempSync(join(tmpdir(), "notch-runtime-check-"));
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    writeFileSync(
      join(parent, "pkg-config"),
      `#!${process.execPath}
const fs = require("node:fs");
const path = require("node:path");
const dir = fs.readdirSync(process.env.TMPDIR).find(
  (entry) => entry.startsWith("notch-lock-isolated-"),
);
fs.chmodSync(path.join(process.env.TMPDIR, dir), 0o755);
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(parent, "cc"),
      `#!${process.execPath}
require("node:fs").writeFileSync(process.env.CC_MARKER, "ran");
`,
      { mode: 0o755 },
    );
    const result = spawnSync(process.execPath, [runner], {
      env: {
        PATH: parent,
        TMPDIR: parent,
        CC_MARKER: join(parent, "compiler"),
      },
      encoding: "utf8",
      timeout: 3000,
    });
    assert.notEqual(result.status, 0, result.stdout);
    assert.match(result.stderr, /unsafe isolated runtime directory/i);
    assert.throws(() => readFileSync(join(parent, "compiler")), {
      code: "ENOENT",
    });
  } finally {
    rmSync(parent, { recursive: true, force: true });
  }
});
