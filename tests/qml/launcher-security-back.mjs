import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("Escape in the security view returns to the command list", () => {
  // An empty state dir: the security view opens with the switch off.
  const dir = mkdtempSync(join(tmpdir(), "notch-security-back-"));
  try {
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-security-back.qml", import.meta.url),
      ),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: dir,
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_POWER_DRY_RUN: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(
      output,
      /security back: Escape returns to the commands and closes/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
