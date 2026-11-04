import { test } from "node:test";
import assert from "node:assert/strict";
import {
  isVideoPath,
  shouldImport,
  videoShouldPlay,
  wallpaperFor,
} from "../shell/logic/wallpaperState.mjs";

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

test("video wallpapers are recognised by extension, in any case", () => {
  assert.equal(isVideoPath("/w/loop.mp4"), true);
  assert.equal(isVideoPath("/w/loop.WEBM"), true);
  assert.equal(isVideoPath("/w/loop.mkv"), true);
});

test("image wallpapers are not videos", () => {
  assert.equal(isVideoPath("/w/arch.png"), false);
  assert.equal(isVideoPath("/w/mp4.jpg"), false);
});

test("a video wallpaper plays while the session is unlocked", () => {
  assert.equal(videoShouldPlay("/w/loop.mp4", false), true);
});

test("a video wallpaper pauses while the session is locked", () => {
  assert.equal(videoShouldPlay("/w/loop.mp4", true), false);
});

test("an image wallpaper never plays", () => {
  assert.equal(videoShouldPlay("/w/arch.png", false), false);
});
