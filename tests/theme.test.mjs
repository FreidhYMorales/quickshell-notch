import { test } from "node:test";
import assert from "node:assert/strict";
import {
  appArgs,
  commitJobs,
  dryArgs,
  frameArgs,
  midpoint,
  MODES,
  parseDryPalette,
  probeArgs,
  themeState,
} from "../shell/logic/theme.mjs";

test("theme modes are the nine matugen scheme types in display order", () => {
  assert.deepEqual(MODES, [
    "scheme-tonal-spot",
    "scheme-monochrome",
    "scheme-vibrant",
    "scheme-expressive",
    "scheme-fidelity",
    "scheme-content",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-fruit-salad",
  ]);
});

test("a dry-run palette keeps the three notch colours", () => {
  const json = JSON.stringify({
    colors: {
      primary: { default: { color: "#aabbcc" } },
      on_surface: { default: { color: "#ddeeff" } },
      on_surface_variant: { default: { color: "#112233" } },
      tertiary: { default: { color: "#000000" } },
    },
  });
  assert.deepEqual(parseDryPalette(json), {
    primary: "#aabbcc",
    onSurface: "#ddeeff",
    muted: "#112233",
  });
});

test("a broken dry-run palette gives null", () => {
  assert.equal(parseDryPalette("not json"), null);
  assert.equal(parseDryPalette(null), null);
  assert.equal(parseDryPalette('{"colors":{}}'), null);
  assert.equal(
    parseDryPalette(
      JSON.stringify({
        colors: {
          primary: { default: { color: "red" } },
          on_surface: { default: { color: "#ddeeff" } },
          on_surface_variant: { default: { color: "#112233" } },
        },
      }),
    ),
    null,
  );
});

test("the app-facing run writes the theme, the dry-run only reads it", () => {
  assert.deepEqual(appArgs("/w/a.png", "scheme-vibrant"), [
    "matugen",
    "image",
    "/w/a.png",
    "--type",
    "scheme-vibrant",
    "--mode",
    "dark",
    "--source-color-index",
    "0",
    "--quiet",
  ]);
  assert.deepEqual(dryArgs("/w/b.png", "scheme-neutral"), [
    "matugen",
    "image",
    "/w/b.png",
    "--type",
    "scheme-neutral",
    "--mode",
    "dark",
    "--source-color-index",
    "0",
    "--dry-run",
    "--quiet",
    "--json",
    "hex",
  ]);
});

test("the notch theme state wins and drops the old dynamic flag", () => {
  assert.deepEqual(
    themeState(
      '{"mode":"scheme-vibrant","dynamic":true}',
      '{"mode":"scheme-neutral"}',
    ),
    { mode: "scheme-vibrant" },
  );
});

test("the old theme is imported only when the notch has no state", () => {
  assert.deepEqual(themeState(null, '{"mode":"scheme-rainbow"}'), {
    mode: "scheme-rainbow",
  });
  assert.deepEqual(themeState("not json", '{"mode":"scheme-rainbow"}'), {
    mode: "scheme-content",
  });
});

test("a missing or broken theme state falls back to scheme-content", () => {
  assert.deepEqual(themeState(null, null), { mode: "scheme-content" });
  assert.deepEqual(themeState("not json", null), { mode: "scheme-content" });
  assert.deepEqual(themeState('{"mode":"scheme-bogus"}', null), {
    mode: "scheme-content",
  });
});

test("a mode choice reruns the apps and every monitor override", () => {
  assert.deepEqual(
    commitJobs({
      kind: "mode",
      wallpaper: "/w/global.png",
      perScreen: { DP1: "/w/a.png", DP2: "/w/b.png" },
    }),
    {
      app: "/w/global.png",
      palettes: [
        { screen: "DP1", path: "/w/a.png" },
        { screen: "DP2", path: "/w/b.png" },
      ],
    },
  );
});

test("a mode choice without overrides only reruns the apps", () => {
  assert.deepEqual(
    commitJobs({ kind: "mode", wallpaper: "/w/global.png", perScreen: {} }),
    { app: "/w/global.png", palettes: [] },
  );
});

test("a shared wallpaper commit reruns the apps only", () => {
  assert.deepEqual(
    commitJobs({
      kind: "wallpaper",
      shared: true,
      path: "/w/new.png",
      perScreen: { DP1: "/w/a.png" },
    }),
    { app: "/w/new.png", palettes: [] },
  );
});

test("a per-monitor commit only recolours that monitor", () => {
  assert.deepEqual(
    commitJobs({
      kind: "wallpaper",
      shared: false,
      screen: "DP2",
      path: "/w/new.png",
      perScreen: { DP1: "/w/a.png", DP2: "/w/b.png" },
    }),
    { app: null, palettes: [{ screen: "DP2", path: "/w/new.png" }] },
  );
});

test("a video is themed from the frame halfway through it", () => {
  assert.equal(midpoint("10"), 5);
  assert.equal(midpoint("10.5\n"), 5.25);
  assert.equal(midpoint("N/A"), null);
  assert.equal(midpoint("0"), null);
  assert.equal(midpoint(""), null);
  assert.deepEqual(probeArgs("/w/clip.mp4"), [
    "ffprobe",
    "-v",
    "error",
    "-show_entries",
    "format=duration",
    "-of",
    "default=nw=1:nk=1",
    "/w/clip.mp4",
  ]);
  assert.deepEqual(frameArgs("/w/clip.mp4", 5, "/c/frame.png"), [
    "ffmpeg",
    "-nostdin",
    "-hide_banner",
    "-loglevel",
    "error",
    "-y",
    "-ss",
    "5",
    "-i",
    "/w/clip.mp4",
    "-frames:v",
    "1",
    "/c/frame.png",
  ]);
});
