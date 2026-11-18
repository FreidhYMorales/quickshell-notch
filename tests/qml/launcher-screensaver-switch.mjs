import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

function run(stateHome, wallpapers, step) {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(
      new URL("./launcher-screensaver-switch.qml", import.meta.url),
    ),
  ], {
    encoding: "utf8",
    timeout: 30000,
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: stateHome,
      QS_WALLPAPER_DIR: wallpapers,
      NOTCH_PROBE_STEP: step ? "1" : "0",
      NOTCH_SMOKE: "0",
      NOTCH_LAUNCH_DRY_RUN: "1",
      NOTCH_POWER_DRY_RUN: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
        .href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  return output;
}

test("the switch hides the picker and turning it off is kept after a restart", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-screensaver-switch-"));
  const file = join(dir, "state", "quickshell-notch", "idle.json");
  try {
    mkdirSync(join(dir, "state", "quickshell-notch"), { recursive: true });
    mkdirSync(join(dir, "walls"));
    writeFileSync(
      file,
      '{"screensaverTimeoutMin":2,"lockTimeoutMin":4,"suspendTimeoutMin":0}',
    );
    const state = join(dir, "state");
    const walls = join(dir, "walls");
    assert.match(
      run(state, walls, true),
      /screensaver switch: picker shown, same as desktop false/,
    );
    assert.equal(
      JSON.parse(readFileSync(file, "utf8")).screensaverUseWallpaper,
      false,
    );
    assert.match(
      run(state, walls, false),
      /screensaver switch: picker shown, same as desktop false/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
