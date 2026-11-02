// Generic reveal reducer shared by the workspaces strip and both OSDs.
// Pure: stepReveal returns a new state plus what the surface's single Timer
// must do ("restart" | "stop" | "none"). No clocks live here.
//
// state: { ready, open, hover, hold, pinned, flash }
//   ready  - the startup gate has passed; Trigger is ignored before it
//   hover  - pointer over the visible shape
//   hold   - an interaction in progress (slider drag)
//   pinned - stays visible with no timer (special workspace)
//   flash  - optional payload shown while open, cleared on hide

export function initialReveal() {
  return {
    ready: false,
    open: false,
    hover: false,
    hold: false,
    pinned: false,
    flash: null,
  };
}

export const isVisible = (s) => s.pinned || s.open;

const held = (s) => s.hover || s.hold || s.pinned;
const next = (s, patch) => Object.assign({}, s, patch);
const result = (state, timer) => ({ state, timer });

// A held surface must not time out; otherwise the timer (re)starts.
const rearm = (s) => result(s, held(s) ? "stop" : "restart");

// Hover and Hold only mean something on a visible surface.
function setHeld(s, key, on) {
  if (on && !isVisible(s)) return result(s, "none");
  if (s[key] === on) return result(s, "none");
  const n = next(s, { [key]: on });
  if (on) return result(n, "stop");
  return held(n) || !isVisible(n) ? result(n, "none") : result(n, "restart");
}

export function stepReveal(state, event) {
  switch (event.type) {
    case "Ready":
      return result(next(state, { ready: true }), "none");
    case "TrayHover":
      if (!state.ready || event.count <= 0) return result(state, "none");
      return rearm(next(state, { open: true, hover: true, row: "tray" }));
    case "ToggleTray":
      return result(
        next(state, { row: state.row === "tray" ? "workspaces" : "tray" }),
        "none",
      );
    case "Trigger": {
      if (!state.ready) return result(state, "none");
      const flash = event.flash === undefined ? state.flash : event.flash;
      const patch = { open: true, flash };
      if (!isVisible(state) && state.row === "tray") patch.row = "workspaces";
      return rearm(next(state, patch));
    }
    case "Hover":
      return setHeld(state, "hover", !!event.on);
    case "Hold":
      return setHeld(state, "hold", !!event.on);
    case "Pin":
      if (event.on) return result(next(state, { pinned: true }), "stop");
      // Leaving the special keeps the strip up for one normal reveal period.
      return rearm(next(state, { pinned: false, open: true }));
    case "Timeout":
      if (held(state) || !state.open) return result(state, "none");
      return result(next(state, { open: false, flash: null }), "none");
    default:
      return result(state, "none");
  }
}
