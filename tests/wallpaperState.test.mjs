import { test } from "node:test";
import assert from "node:assert/strict";
import {
  isVideoPath,
  needsThemeFrame,
  normalizePerScreen,
  shouldImport,
  videoShouldPlay,
  wallpaperFor,
} from "../shell/logic/wallpaperState.mjs";

test("animated GIFs and videos need a frame for their theme", () => {
  assert.equal(needsThemeFrame("/w/loop.GIF"), true);
  assert.equal(needsThemeFrame("/w/loop.mp4"), true);
  assert.equal(needsThemeFrame("/w/still.png"), false);
});

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

test("a temporary preview overrides only its target monitor", async () => {
  const { previewFor } = await import("../shell/logic/wallpaperState.mjs");
  const overrides = { "DP-1": "/w/dp.png" };
  assert.equal(
    previewFor(overrides, "/w/base.png", "DP-1", {
      screen: "DP-1",
      path: "/w/new.png",
    }),
    "/w/new.png",
  );
  assert.equal(
    previewFor(overrides, "/w/base.png", "eDP-1", {
      screen: "DP-1",
      path: "/w/new.png",
    }),
    "/w/base.png",
  );
});

test("committing to a monitor preserves other overrides", async () => {
  const { commitFor } = await import("../shell/logic/wallpaperState.mjs");
  const original = { "DP-1": "/w/old.png", "HDMI-A-1": "/w/other.png" };
  const next = commitFor(original, "/w/default.png", "DP-1", "/w/new.png");
  assert.equal(next.perScreen["DP-1"], "/w/new.png");
  assert.equal(next.perScreen["HDMI-A-1"], "/w/other.png");
  assert.equal(next.fallback, "/w/default.png");
  assert.equal(original["DP-1"], "/w/old.png");
});

test("a global temporary preview applies across monitors without changing committed state", async () => {
  const { previewFor } = await import("../shell/logic/wallpaperState.mjs");
  const overrides = { "DP-1": "/w/dp.png" };
  const preview = { screen: "", path: "/w/temporary.png" };
  assert.equal(
    previewFor(overrides, "/w/base.png", "DP-1", preview),
    "/w/temporary.png",
  );
  assert.equal(
    previewFor(overrides, "/w/base.png", "eDP-1", preview),
    "/w/temporary.png",
  );
  assert.equal(previewFor(overrides, "/w/base.png", "DP-1", null), "/w/dp.png");
});

test("malformed monitor state is normalized before use", () => {
  assert.deepEqual(normalizePerScreen(null), {});
  assert.deepEqual(normalizePerScreen(["/w/a.png"]), {});
  assert.deepEqual(normalizePerScreen("invalid"), {});
  assert.deepEqual(
    normalizePerScreen({ "DP-1": "/w/a.png", "eDP-1": 12, "HDMI-1": "" }),
    { "DP-1": "/w/a.png" },
  );
});

test("monitor state excludes dangerous inherited keys", () => {
  const value = JSON.parse(
    '{"__proto__":"/w/evil.png","constructor":"/w/b.png","DP-1":"/w/ok.png"}',
  );
  assert.deepEqual(normalizePerScreen(value), { "DP-1": "/w/ok.png" });
  assert.equal(shouldImport(null, ""), true);
});

test("shared commit replaces all monitor overrides and updates fallback", async () => {
  const { commitShared } = await import("../shell/logic/wallpaperState.mjs");
  const next = commitShared("/w/shared.mp4");
  assert.deepEqual(next, { perScreen: {}, fallback: "/w/shared.mp4" });
  assert.equal(
    wallpaperFor(next.perScreen, next.fallback, "DP-1"),
    "/w/shared.mp4",
  );
  assert.equal(
    wallpaperFor(next.perScreen, next.fallback, "HDMI-A-1"),
    "/w/shared.mp4",
  );
});
