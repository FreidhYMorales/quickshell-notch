import test from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_THEME,
  MODES,
  PRESETS,
  normalizeTheme,
  parseTheme,
  selectTheme,
  themePalette,
} from "../shell/logic/themeState.mjs";

test("invalid persisted values return safe defaults", () => {
  assert.deepEqual(parseTheme("not json"), DEFAULT_THEME);
  assert.deepEqual(normalizeTheme({ mode: "unknown", preset: "bad" }), DEFAULT_THEME);
});

test("both modes and all palette presets are selectable", () => {
  for (const mode of MODES) {
    for (const preset of PRESETS) {
      const state = selectTheme(DEFAULT_THEME, mode, preset.id);
      assert.deepEqual(state, { mode, preset: preset.id });
      assert.match(themePalette(state, null).primary, /^#[0-9a-f]{6}$/i);
    }
  }
});

test("automatic preset uses wallpaper accent and mode-specific text", () => {
  const matugen = { primary: "#123456" };
  assert.equal(themePalette({ mode: "dark", preset: "auto" }, matugen).primary, "#123456");
  assert.equal(themePalette({ mode: "light", preset: "auto" }, matugen).primary, "#123456");
  assert.notEqual(
    themePalette({ mode: "dark", preset: "auto" }, matugen).onSurface,
    themePalette({ mode: "light", preset: "auto" }, matugen).onSurface,
  );
});

test("fixed presets ignore wallpaper palette and preserve mode", () => {
  const selected = selectTheme({ mode: "light", preset: "ocean" }, null, "violet");
  assert.equal(selected.mode, "light");
  assert.equal(selected.preset, "violet");
  assert.equal(themePalette(selected, { primary: "#ffffff" }).primary, "#6750a4");
});
