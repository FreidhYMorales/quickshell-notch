import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("checks prerequisites before creating a runtime", () => {
  const parent = mkdtempSync(join(tmpdir(), "notch-before-runtime-"));
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    writeFileSync(
      join(parent, "pkg-config"),
      `#!${process.execPath}
const fs = require("node:fs");
fs.writeFileSync(process.env.MARKER, JSON.stringify(fs.readdirSync(process.env.TMPDIR)));
process.exit(1);
`,
      { mode: 0o755 },
    );
    const result = spawnSync(process.execPath, [runner], {
      env: { PATH: parent, TMPDIR: parent, MARKER: join(parent, "seen") },
      encoding: "utf8",
      timeout: 3000,
    });
    assert.notEqual(result.status, 0);
    assert.deepEqual(JSON.parse(readFileSync(join(parent, "seen"), "utf8")), [
      "pkg-config",
    ]);
  } finally {
    rmSync(parent, { recursive: true, force: true });
  }
});
