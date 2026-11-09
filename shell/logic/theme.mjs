// Pure theme model: the matugen scheme types the launcher offers, in the
// display order the old config used.

export const MODES = [
  "scheme-tonal-spot",
  "scheme-monochrome",
  "scheme-vibrant",
  "scheme-expressive",
  "scheme-fidelity",
  "scheme-content",
  "scheme-neutral",
  "scheme-rainbow",
  "scheme-fruit-salad",
];

const HEX = /^#[0-9a-fA-F]{6}$/;

// Argv arrays, no shell. The app-facing run writes colors.json and runs the
// post-hook; the dry-run only dumps one monitor's palette. The notch stays
// dark in this story: #40 adds the app-only light/dark axis.
const baseArgs = (path, mode) => [
  "matugen",
  "image",
  path,
  "--type",
  mode,
  "--mode",
  "dark",
  "--source-color-index",
  "0",
];

export function appArgs(path, mode) {
  return baseArgs(path, mode).concat(["--quiet"]);
}

export function dryArgs(path, mode) {
  return baseArgs(path, mode).concat(["--dry-run", "--quiet", "--json", "hex"]);
}

export const DEFAULT_MODE = "scheme-content";

// The notch's theme.json keeps only the mode; the old shell's file used the
// same key. A missing or broken notch file keeps the default rather than
// reading the old file, so importing happens once, never after an edit.
export function themeState(notchText, oldText) {
  const text = typeof notchText === "string" ? notchText : oldText;
  let saved = {};
  if (typeof text === "string") {
    try {
      saved = JSON.parse(text) || {};
    } catch (_error) {
      saved = {};
    }
  }
  const mode = MODES.indexOf(saved.mode) === -1 ? DEFAULT_MODE : saved.mode;
  return { mode };
}

// Which matugen runs a commit implies. A mode choice rebuilds the apps from
// the shared wallpaper and every monitor override from its own; a shared
// wallpaper commit only rebuilds the apps (monitors without an override
// follow the new global palette); an override only recolours its monitor.
export function commitJobs(action) {
  if (action.kind === "mode") {
    const palettes = [];
    for (const screen in action.perScreen) {
      palettes.push({ screen: screen, path: action.perScreen[screen] });
    }
    return { app: action.wallpaper, palettes: palettes };
  }
  if (action.shared) return { app: action.path, palettes: [] };
  return {
    app: null,
    palettes: [{ screen: action.screen, path: action.path }],
  };
}

// matugen --dry-run --json hex nests each colour as { default: { color } },
// unlike the { hex } shape of the colors.json it writes for the apps.
export function parseDryPalette(jsonText) {
  if (typeof jsonText !== "string") return null;
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (_error) {
    return null;
  }
  const colors = data?.colors;
  if (typeof colors !== "object" || colors === null) return null;
  const primary = colors.primary?.default?.color;
  const onSurface = colors.on_surface?.default?.color;
  const muted = colors.on_surface_variant?.default?.color;
  if (!HEX.test(primary) || !HEX.test(onSurface) || !HEX.test(muted)) {
    return null;
  }
  return { primary, onSurface, muted };
}

// matugen reads images only, so a video wallpaper is themed from one still
// frame: the middle of the file, where a short intro cannot decide the whole
// palette. ffprobe gives the duration, ffmpeg writes the frame.
export function probeArgs(path) {
  return [
    "ffprobe",
    "-v",
    "error",
    "-show_entries",
    "format=duration",
    "-of",
    "default=nw=1:nk=1",
    path,
  ];
}

export function frameArgs(path, seconds, output) {
  return [
    "ffmpeg",
    "-nostdin",
    "-hide_banner",
    "-loglevel",
    "error",
    "-y",
    "-ss",
    String(seconds),
    "-i",
    path,
    "-frames:v",
    "1",
    output,
  ];
}

export function midpoint(text) {
  if (typeof text !== "string") return null;
  const duration = Number.parseFloat(text);
  if (!Number.isFinite(duration) || duration <= 0) return null;
  return duration / 2;
}
