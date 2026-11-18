import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("activating Screensaver shows the stored times", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-screensaver-view-"));
  try {
    mkdirSync(join(dir, "quickshell-notch"));
    writeFileSync(
      join(dir, "quickshell-notch", "idle.json"),
      '{"screensaverTimeoutMin":2,"lockTimeoutMin":4,"suspendTimeoutMin":0}',
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-screensaver-view.qml", import.meta.url),
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
    assert.match(output, /screensaver view: 2 min, 4 min and Off shown/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
