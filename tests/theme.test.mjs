import { test } from "node:test";
import assert from "node:assert/strict";
import {
  appArgs,
  dryArgs,
  MODES,
  parseDryPalette,
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
