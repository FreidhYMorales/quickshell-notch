import { test } from "node:test";
import assert from "node:assert/strict";
import { shouldImport, wallpaperFor } from "../shell/logic/wallpaperState.mjs";

test("a screen listed in the per-screen state gets its own wallpaper", () => {
  const perScreen = { "DP-1": "/w/video.mp4", "eDP-1": "/w/arch.png" };
  assert.equal(
    wallpaperFor(perScreen, "/w/default.jpg", "DP-1"),
    "/w/video.mp4",
  );
});

test("a screen missing from the per-screen state gets the default wallpaper", () => {
  const perScreen = { "DP-1": "/w/video.mp4" };
  assert.equal(
    wallpaperFor(perScreen, "/w/default.jpg", "HDMI-A-1"),
    "/w/default.jpg",
  );
});

test("an empty notch state imports the old shell's wallpaper", () => {
  assert.equal(shouldImport({}, ""), true);
});

test("a notch state with a default wallpaper keeps it", () => {
  assert.equal(shouldImport({}, "/w/default.jpg"), false);
});

test("a notch state with per-screen wallpapers keeps them", () => {
  assert.equal(shouldImport({ "DP-1": "/w/video.mp4" }, ""), false);
});
