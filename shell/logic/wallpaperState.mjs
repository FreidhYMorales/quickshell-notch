// Pure wallpaper state decisions (no Quickshell/Qt imports).

// perScreen: { [screenName]: path }. A screen without its own entry shows
// the default wallpaper.
export function wallpaperFor(perScreen, fallback, screen) {
  const own = perScreen ? perScreen[screen] : undefined;
  return own ? own : fallback;
}
