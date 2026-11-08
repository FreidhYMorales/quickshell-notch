// Pure theme selection and validation. No Qt or filesystem access.
export const MODES = ["dark", "light"];
export const PRESETS = [
  { id: "auto", name: "Wallpaper", dark: "#adc6ff", light: "#315da8" },
  { id: "ocean", name: "Ocean", dark: "#86d4ed", light: "#006780" },
  { id: "forest", name: "Forest", dark: "#a4d5ad", light: "#246b3c" },
  { id: "sunset", name: "Sunset", dark: "#ffb59b", light: "#9c402b" },
  { id: "violet", name: "Violet", dark: "#d0bcff", light: "#6750a4" },
];
export const DEFAULT_THEME = Object.freeze({ mode: "dark", preset: "auto" });

export function normalizeTheme(value) {
  return {
    mode: MODES.includes(value?.mode) ? value.mode : DEFAULT_THEME.mode,
    preset: PRESETS.some((p) => p.id === value?.preset)
      ? value.preset
      : DEFAULT_THEME.preset,
  };
}

export function parseTheme(text) {
  try {
    return normalizeTheme(JSON.parse(text));
  } catch (_error) {
    return Object.assign({}, DEFAULT_THEME);
  }
}

export function themePalette(theme, matugen) {
  const { mode, preset } = normalizeTheme(theme);
  const entry = PRESETS.find((p) => p.id === preset);
  const automatic = preset === "auto";
  const primary = automatic
    ? (matugen?.primary ?? (mode === "dark" ? entry.dark : entry.light))
    : entry[mode];
  return {
    primary,
    onSurface: mode === "dark" ? "#e2e2e9" : "#1b1b20",
    muted: mode === "dark" ? "#c4c6d0" : "#50535b",
  };
}

export function selectTheme(theme, mode, preset) {
  return normalizeTheme({ mode: mode ?? theme?.mode, preset: preset ?? theme?.preset });
}
