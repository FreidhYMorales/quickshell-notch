// Pure catalog and temporary selection decisions for both wallpaper pickers.
// The caller owns persistence; browsing must never write committed state.

const SUPPORTED = /\.(png|jpe?g|webp|bmp|avi|mp4|mov|mkv|m4v|webm)$/i;
const VIDEO = /\.(avi|mp4|mov|mkv|m4v|webm)$/i;

export function catalogEntries(paths) {
  const entries = [];
  const seen = new Set();
  for (const path of paths ?? []) {
    if (typeof path !== "string" || !SUPPORTED.test(path) || seen.has(path)) continue;
    seen.add(path);
    entries.push({
      path,
      name: path.slice(path.lastIndexOf("/") + 1),
      video: VIDEO.test(path),
    });
  }
  entries.sort((a, b) => {
    const first = a.name.toLowerCase();
    const second = b.name.toLowerCase();
    if (first !== second) return first < second ? -1 : 1;
    return a.path < b.path ? -1 : a.path > b.path ? 1 : 0;
  });
  return entries;
}

export function beginPreview(entries, original) {
  const index = entries.findIndex((entry) => entry.path === original);
  const selected = entries.length ? Math.max(0, index) : -1;
  return {
    entries,
    original: original ?? "",
    index: selected,
    preview: selected < 0 ? "" : entries[selected].path,
  };
}

export function movePreview(session, step) {
  const count = session.entries.length;
  if (!count) return session;
  const index = ((session.index + step) % count + count) % count;
  return Object.assign({}, session, {
    index,
    preview: session.entries[index].path,
  });
}

export function cancelPreview(session) {
  return session.original;
}

export function commitPreview(session) {
  return session.index < 0 ? null : session.preview;
}

// A live folder update must not leave a selection pointing at a removed file.
// Preserve the highlighted path if it still exists; otherwise prefer the
// committed wallpaper, then the first available entry.
export function refreshPreview(session, entries) {
  if (!session) return null;
  const preferred = entries.some((entry) => entry.path === session.preview)
    ? session.preview
    : session.original;
  const next = beginPreview(entries, preferred);
  return Object.assign({}, next, { original: session.original });
}
