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
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("first run imports the old shell's wallpapers and leaves its files untouched", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-wallpaper-import-");
  const old = join(dir, "quickshell");
  const oldDefault = "/w/arch.png\n";
  const oldScreens = '{"DP-1":"/w/loop.mp4"}';
  try {
    mkdirSync(old);
    writeFileSync(join(old, "wallpaper.txt"), oldDefault);
    writeFileSync(join(old, "wallpaper-screens.json"), oldScreens);
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./wallpaper-import.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: dir,
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /wallpaper DP-1: \/w\/loop\.mp4/);
    assert.match(output, /wallpaper HDMI-A-1: \/w\/arch\.png/);
    const notch = join(dir, "quickshell-notch");
    assert.equal(
      readFileSync(join(notch, "wallpaper.txt"), "utf8"),
      "/w/arch.png",
    );
    assert.deepEqual(
      JSON.parse(readFileSync(join(notch, "wallpaper-screens.json"), "utf8")),
      { "DP-1": "/w/loop.mp4" },
    );
    assert.equal(readFileSync(join(old, "wallpaper.txt"), "utf8"), oldDefault);
    assert.equal(
      readFileSync(join(old, "wallpaper-screens.json"), "utf8"),
      oldScreens,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
