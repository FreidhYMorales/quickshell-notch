import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("Wallpaper command displays its glyph", () => {
  const probe = fileURLToPath(
    new URL("./launcher-wallpaper-glyph.qml", import.meta.url),
  );
  const result = spawnSync("qs", ["-p", probe], {
    encoding: "utf8",
    timeout: 20000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_LAUNCH_DRY_RUN: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /launcher glyphs: Wallpaper shown/);
});
