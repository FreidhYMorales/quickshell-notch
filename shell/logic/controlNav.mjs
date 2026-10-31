// Pure navigation of the control center: the root panel and its subpages.
// No Qt imports.

const ROOT = "root";
const NOTIFICATIONS = "notifications";

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
