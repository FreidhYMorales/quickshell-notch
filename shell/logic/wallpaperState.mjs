// Pure wallpaper state decisions (no Quickshell/Qt imports).

// perScreen: { [screenName]: path }. A screen without its own entry shows
// the default wallpaper.
export function wallpaperFor(perScreen, fallback, screen) {
  const own = perScreen ? perScreen[screen] : undefined;
  return own ? own : fallback;
}

// The old shell's state is imported once: only while the notch state holds
// neither a default nor any per-screen wallpaper.
export function shouldImport(perScreen, fallback) {
  if (fallback) return false;
  for (const screen in perScreen ?? {}) {
    if (perScreen[screen]) return false;
  }
  return true;
}

const VIDEO = /\.(avi|mp4|mov|mkv|m4v|webm)$/i;

export function isVideoPath(path) {
  return VIDEO.test(path ?? "");
}

// A video wallpaper pauses while the session is locked (the lock surface may
// play its own video).
export function videoShouldPlay(path, locked) {
  return isVideoPath(path) && !locked;
}

export function previewFor(perScreen, fallback, screen, preview) {
  if (preview && (preview.screen === screen || preview.screen === "")) {
    return preview.path;
  }
  return wallpaperFor(perScreen, fallback, screen);
}

export function commitFor(perScreen, fallback, screen, path) {
  const next = Object.assign({}, perScreen);
  if (screen) next[screen] = path;
  else return { perScreen: next, fallback: path };
  return { perScreen: next, fallback };
}

// Treat saved JSON as untrusted input. A corrupt or legacy state file must not
// introduce non-string paths or inherited properties into monitor lookup.
export function normalizePerScreen(value) {
  const clean = {};
  if (!value || typeof value !== "object" || Array.isArray(value)) return clean;
  for (const name of Object.keys(value)) {
    if (
      name === "__proto__" || name === "constructor" || name === "prototype"
    ) continue;
    if (typeof value[name] === "string" && value[name].trim()) {
      clean[name] = value[name];
    }
  }
  return clean;
}

// Applying to all monitors clears per-monitor overrides so newly connected
// monitors also inherit the shared wallpaper.
export function commitShared(path) {
  return { perScreen: {}, fallback: path };
}
