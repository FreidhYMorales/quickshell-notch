// Pure navigation of the control center: the root panel and its subpages.
// No Qt imports.

const ROOT = "root";
const NOTIFICATIONS = "notifications";

export { NOTIFICATIONS, ROOT };

export function initialView() {
  return ROOT;
}

// Both entry points ("See all" and the DND right click) land here.
export function openSubpage() {
  return NOTIFICATIONS;
}

export function back() {
  return ROOT;
}

// A brief pointer leave must not close a subpage; the surface waits for the
// longer leave. The root collapses at once, as before.
export function closeOnLeave(view) {
  return view === ROOT ? "now" : "wait";
}

export function panelHeight(_view, _rootHeight, _subHeight) {}
