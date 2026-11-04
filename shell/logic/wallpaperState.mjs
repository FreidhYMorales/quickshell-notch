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
  for (const screen in perScreen) {
    if (perScreen[screen]) return false;
  }
  return true;
}
