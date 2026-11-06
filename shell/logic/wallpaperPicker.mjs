// Pure catalog and temporary selection decisions for both wallpaper pickers.
// The caller owns persistence; browsing must never write committed state.

const SUPPORTED = /\.(png|jpe?g|webp|bmp|avi|mp4|mov|mkv|m4v|webm)$/i;
const VIDEO = /\.(avi|mp4|mov|mkv|m4v|webm)$/i;

export function catalogEntries(paths) {
  const entries = [];
  for (const path of paths ?? []) {
    if (typeof path !== "string" || !SUPPORTED.test(path)) continue;
    entries.push({
      path,
      name: path.slice(path.lastIndexOf("/") + 1),
      video: VIDEO.test(path),
    });
  }
  entries.sort((a, b) => {
    const first = a.name.toLowerCase();
    const second = b.name.toLowerCase();
    return first < second ? -1 : first > second ? 1 : 0;
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
