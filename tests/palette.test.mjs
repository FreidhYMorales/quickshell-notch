import { test } from "node:test";
import assert from "node:assert/strict";
import { parsePalette } from "../shell/logic/palette.mjs";

const colors = (over = {}) =>
  JSON.stringify({
    scheme: "dark",
    colors: {
      primary: { hex: "#adc6ff" },
      on_surface: { hex: "#e2e2e9" },
      on_surface_variant: { hex: "#c4c6d0" },
      ...over,
    },
  });

test("valid matugen JSON yields primary, onSurface and muted", () => {
  assert.deepEqual(parsePalette(colors()), {
    primary: "#adc6ff",
    onSurface: "#e2e2e9",
    muted: "#c4c6d0",
  });
});

test("a different wallpaper yields its own primary", () => {
  assert.equal(
    parsePalette(colors({ primary: { hex: "#ffb4a8" } })).primary,
    "#ffb4a8",
  );
});

test("uppercase hex is normalised to lowercase", () => {
  assert.equal(
    parsePalette(colors({ primary: { hex: "#ADC6FF" } })).primary,
    "#adc6ff",
  );
});

test("missing or non-string input returns null", () => {
  assert.equal(parsePalette(undefined), null);
  assert.equal(parsePalette(null), null);
  assert.equal(parsePalette(""), null);
  assert.equal(parsePalette(42), null);
});

test("malformed JSON and wrong shapes return null", () => {
  assert.equal(parsePalette("{not json"), null);
  assert.equal(parsePalette("[]"), null);
  assert.equal(parsePalette("{}"), null);
  assert.equal(parsePalette('{"colors": 3}'), null);
});

test("a missing required colour returns null", () => {
  const text = JSON.stringify({ colors: { primary: { hex: "#adc6ff" } } });
  assert.equal(parsePalette(text), null);
});

test("an invalid hex value returns null", () => {
  assert.equal(parsePalette(colors({ primary: { hex: "blue" } })), null);
  assert.equal(parsePalette(colors({ primary: { hex: "#12345" } })), null);
  assert.equal(parsePalette(colors({ primary: "#adc6ff" })), null);
});
