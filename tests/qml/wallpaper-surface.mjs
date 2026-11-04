import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("a screen's background surface loads that screen's wallpaper", () => {
  const result = runTrayProbe("./wallpaper-surface.qml", {
    NOTCH_TEST_SURFACE: new URL(
      "../../shell/components/WallpaperSurface.qml",
      import.meta.url,
    ).href,
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /wallpaper surface: own wallpaper shown/);
});
