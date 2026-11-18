import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("cleans its runtime when prerequisite discovery fails", () => {
  const parent = mkdtempSync(join(tmpdir(), "notch-cleanup-check-"));
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    writeFileSync(join(parent, "pkg-config"), "#!/bin/sh\nexit 1\n", {
      mode: 0o755,
    });
    const result = spawnSync(process.execPath, [runner], {
      env: { PATH: parent, TMPDIR: parent },
      encoding: "utf8",
      timeout: 3000,
    });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /wlroots 0\.20 development headers/);
    assert.deepEqual(readdirSync(parent), ["pkg-config"]);
  } finally {
    rmSync(parent, { recursive: true, force: true });
  }
});
