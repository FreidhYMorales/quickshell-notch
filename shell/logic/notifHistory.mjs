// Pure session history of notifications, newest first. No Qt imports.

// A new id goes first; a known id (`replaces-id`) is refreshed where it is.
// Past `cap` the oldest are dropped.
export function addToHistory(history, notif, cap) {
  if (history.some((n) => n.id === notif.id)) {
    return history.map((n) => (n.id === notif.id ? notif : n));
  }
  return [notif].concat(history).slice(0, cap);
}

// Closed by its app, dismissed, or cleared: it leaves the history.
export function removeFromHistory(history, id) {
  return history.filter((n) => n.id !== id);
}

// The newest `count` entries (the control center's inline list).
export function latest(history, count) {
  return history.slice(0, count);
}
