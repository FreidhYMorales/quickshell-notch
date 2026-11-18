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
    fileURLToPath(new URL("./launcher-screensaver-pick.qml", import.meta.url)),
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

test("with the switch off, picking a wallpaper saves it and it is kept after a restart", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-screensaver-pick-"));
  const state = join(dir, "state");
  const walls = join(dir, "walls");
  const file = join(state, "quickshell-notch", "idle.json");
  try {
    mkdirSync(join(state, "quickshell-notch"), { recursive: true });
    mkdirSync(walls);
    writeFileSync(join(walls, "a.png"), "");
    writeFileSync(join(walls, "b.png"), "");
    writeFileSync(
      file,
      '{"screensaverTimeoutMin":2,"lockTimeoutMin":4,"suspendTimeoutMin":0,"screensaverUseWallpaper":false,"screensaverPath":""}',
    );
    assert.match(
      run(state, walls, true),
      /screensaver pick: chosen b\.png, same as desktop false/,
    );
    assert.equal(
      JSON.parse(readFileSync(file, "utf8")).screensaverPath,
      join(walls, "b.png"),
    );
    assert.match(
      run(state, walls, false),
      /screensaver pick: chosen b\.png, same as desktop false/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
