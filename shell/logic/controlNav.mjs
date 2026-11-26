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

// Keybind entry points: `qs -c notch ipc call controlcenter open|notifications`.
// Unknown commands are ignored instead of opening some view by accident.
export function commandView(command) {
  if (command === "open") return ROOT;
  if (command === "notifications") return NOTIFICATIONS;
  return null;
}

// A panel keybind is a toggle for its own view, and a switch when another
// control-center view is already open.
export function toggleCommand(open, currentView, requestedView) {
  if (open && currentView === requestedView) {
    return { open: false, view: currentView };
  }
  return { open: true, view: requestedView };
}

export function back() {
  return ROOT;
}

// A brief pointer leave must not close a subpage; the surface waits for the
// longer leave. The root collapses at once, as before.
export function closeOnLeave(view) {
  return view === ROOT ? "now" : "wait";
}

// The drawn panel never shrinks below the root around a subpage: the input
// mask follows it, and a mask that slid out from under the pointer would close
// the panel on its own.
export function panelHeight(view, rootHeight, subHeight) {
  return view === ROOT ? rootHeight : Math.max(rootHeight, subHeight);
}
