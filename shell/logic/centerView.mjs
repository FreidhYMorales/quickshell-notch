// Pure view selector for the centre notch. The mode is derived, never stored:
// polkit > power > launcher > toast > expanded > idle.

const KEYBOARD_MODES = ["launcher", "power"];

const toastFor = (toast, monitor) =>
  toast?.phase === "shown"
    ? {
      id: toast.id,
      critical: toast.critical,
      expanded: monitor.hovered,
      paused: monitor.hovered || monitor.toastHovered,
    }
    : null;

export function viewFor(state, name) {
  const { keyboard, polkit, toast, blinkDot } = state.global;
  const monitor = state.monitors[name] ?? {};
  const ownsKeyboard = keyboard?.owner === name;
  const ownsPolkit = polkit?.owner === name;
  const shownToast = toastFor(toast, monitor);

  let mode = "idle";
  if (ownsPolkit) mode = "polkit";
  else if (ownsKeyboard && KEYBOARD_MODES.includes(keyboard.kind)) {
    mode = keyboard.kind;
  } else if (shownToast) mode = "toast";
  else if (monitor.hovered || monitor.pinned) mode = "expanded";

  const keyboardMode = mode === "launcher" || mode === "power";
  const view = {
    mode,
    sub: keyboardMode ? keyboard.sub : null,
    hold: mode === "power" ? keyboard.hold : null,
    toast: mode === "toast" ? shownToast : null,
    showCriticalIndicator: toast?.phase === "indicator",
    blinkDot,
    keyboardFocus: keyboardMode || mode === "polkit" ? "exclusive" : "none",
  };
  // Only the launcher carries a query and a selected result.
  if (mode === "launcher") {
    view.query = keyboard.query ?? "";
    view.index = keyboard.index ?? 0;
  }
  // Only the expanded notch carries its calendar: the week around today
  // unless the monitor browsed away or opened the month.
  if (mode === "expanded") {
    view.calendar = monitor.calendar ?? { view: "week", offset: 0 };
  }
  return view;
}

// The shape key the notch sizes by: an open month is taller than the week.
export function shapeMode(view) {
  return view.mode === "expanded" && view.calendar.view === "month"
    ? "month"
    : view.mode;
}

// The toast timer is global: a hover on any monitor pauses it everywhere.
export function toastPaused(state) {
  // Object.keys, not Object.values: stick to what the reducer already runs on V4.
  return Object.keys(state.monitors).some((name) => {
    const m = state.monitors[name];
    return m.hovered || m.toastHovered;
  });
}

// The unread dot is global: it shows while something arrived since the last
// mark-seen, and blinks while an open keyboard state or polkit mutes toasts.
export function unreadDot(state, unread) {
  const { keyboard, polkit } = state.global;
  return {
    visible: unread,
    blinking: unread && (keyboard !== null || polkit !== null),
  };
}
