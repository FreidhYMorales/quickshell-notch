import { test } from "node:test";
import assert from "node:assert/strict";
import {
  closeQuickWallpaper,
  initialQuickWallpaper,
  openQuickWallpaper,
  quickWallpaperClosed,
  quickWallpaperInteractive,
  quickWallpaperOpened,
  quickWallpaperVisible,
} from "../shell/logic/quickWallpaper.mjs";

test("picker opens on an explicit monitor without changing wallpapers", () => {
  const start = initialQuickWallpaper();
  const opening = openQuickWallpaper(start, "eDP-1");
  assert.deepEqual(opening, { phase: "opening", monitor: "eDP-1" });
  assert.deepEqual(start, { phase: "closed", monitor: null });
  assert.equal(quickWallpaperVisible(opening), true);
  assert.equal(quickWallpaperInteractive(opening), false);
  assert.equal(quickWallpaperInteractive(quickWallpaperOpened(opening)), true);
});

test("invalid monitor does not open a fullscreen picker", () => {
  const start = initialQuickWallpaper();
  assert.equal(openQuickWallpaper(start, ""), start);
  assert.equal(openQuickWallpaper(start, null), start);
});

test("closing preserves monitor during exit and resets after completion", () => {
  const opened = quickWallpaperOpened(
    openQuickWallpaper(initialQuickWallpaper(), "DP-1"),
  );
  const closing = closeQuickWallpaper(opened);
  assert.deepEqual(closing, { phase: "closing", monitor: "DP-1" });
  assert.equal(quickWallpaperVisible(closing), true);
  assert.equal(quickWallpaperInteractive(closing), false);
  assert.deepEqual(quickWallpaperClosed(closing), initialQuickWallpaper());
});

test("out-of-order transition completion is ignored", () => {
  const start = initialQuickWallpaper();
  assert.equal(quickWallpaperOpened(start), start);
  assert.equal(quickWallpaperClosed(start), start);
  const closing = closeQuickWallpaper(openQuickWallpaper(start, "eDP-1"));
  assert.equal(quickWallpaperOpened(closing), closing);
  assert.equal(closeQuickWallpaper(closing), closing);
});


test("opening and closing remain visible but never accept input", () => {
  const opening = openQuickWallpaper(initialQuickWallpaper(), "eDP-1");
  const closing = closeQuickWallpaper(opening);
  assert.equal(quickWallpaperVisible(opening), true);
  assert.equal(quickWallpaperInteractive(opening), false);
  assert.equal(quickWallpaperVisible(closing), true);
  assert.equal(quickWallpaperInteractive(closing), false);
  assert.deepEqual(quickWallpaperClosed(closing), initialQuickWallpaper());
});

test("reopening after a complete close targets the new monitor", () => {
  const first = quickWallpaperOpened(
    openQuickWallpaper(initialQuickWallpaper(), "eDP-1"),
  );
  const closed = quickWallpaperClosed(closeQuickWallpaper(first));
  const second = openQuickWallpaper(closed, "HDMI-A-1");
  assert.deepEqual(second, { phase: "opening", monitor: "HDMI-A-1" });
  assert.deepEqual(quickWallpaperOpened(second), {
    phase: "open",
    monitor: "HDMI-A-1",
  });
});

test("closing an already closed picker is a no-op", () => {
  const closed = initialQuickWallpaper();
  assert.equal(closeQuickWallpaper(closed), closed);
  assert.equal(quickWallpaperVisible(closed), false);
  assert.equal(quickWallpaperInteractive(closed), false);
});
