import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// Resolved before PATH is emptied, so the test never depends on a system
// directory that might happen to ship a helper.
const qs = process.env.PATH.split(":")
  .map((dir) => join(dir, "qs"))
  .find((candidate) => existsSync(candidate));

test("a missing helper shows it as unavailable instead of hanging", () => {
  assert.ok(qs, "qs not found on PATH");
  const dir = mkdtempSync("/tmp/opencode/notch-webapp-missing-");
  const bin = join(dir, "bin");
  try {
    // PATH holds one empty directory: no helper can be found, here or in any
    // system directory that might one day provide one.
    mkdirSync(bin);
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./launcher-webapp-missing.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        PATH: bin,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /webapp missing: helper reported as unavailable/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
