// Pure state transitions for the fullscreen Quick Wallpaper surface.
// Wallpaper selection and persistence remain owned by Wallpapers.qml.

export function initialQuickWallpaper() {
  return { phase: "closed", monitor: null };
}

export function openQuickWallpaper(state, monitor) {
  if (typeof monitor !== "string" || !monitor.length) return state;
  return { phase: "opening", monitor };
}

export function quickWallpaperOpened(state) {
  if (state.phase !== "opening") return state;
  return { ...state, phase: "open" };
}

export function closeQuickWallpaper(state) {
  if (state.phase === "closed" || state.phase === "closing") return state;
  return { ...state, phase: "closing" };
}

export function quickWallpaperClosed(state) {
  if (state.phase !== "closing") return state;
  return initialQuickWallpaper();
}

export function quickWallpaperVisible(state) {
  return state.phase !== "closed";
}

export function quickWallpaperInteractive(state) {
  return state.phase === "open";
}
