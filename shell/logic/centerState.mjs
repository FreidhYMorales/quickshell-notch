// Pure reducer for the centre notch. No Qt imports, no I/O, no timers.
// reduce(state, event) -> { state, effects }

const freshMonitor = () => ({
  hovered: false,
  pinned: false,
  toastHovered: false,
});

export function initialState(monitorNames) {
  const monitors = {};
  for (const name of monitorNames) monitors[name] = freshMonitor();
  return {
    global: {
      locked: false,
      dnd: false,
      blinkDot: false,
      toast: null,
      keyboard: null,
      polkit: null,
    },
    monitors,
  };
}

const withMonitor = (state, name, patch) => ({
  ...state,
  monitors: {
    ...state.monitors,
    [name]: { ...state.monitors[name], ...patch },
  },
});

const unchanged = (state) => ({ state, effects: [] });

const setGlobal = (state, patch) => ({
  state: { ...state, global: { ...state.global, ...patch } },
  effects: [],
});

// Opens or replaces the keyboard slot. Only the current owner (or anyone, when
// the slot is empty) may change it; unknown monitors are ignored.
const openKeyboard = (state, monitor, kind, sub) => {
  const { keyboard } = state.global;
  if (!state.monitors[monitor]) return unchanged(state);
  if (keyboard && keyboard.owner !== monitor) return unchanged(state);
  return setGlobal(state, {
    keyboard: { owner: monitor, kind, sub, hold: null },
  });
};

const handlers = {
  ScreensChanged(state, { names }) {
    const monitors = { ...state.monitors };
    for (const name of names) monitors[name] ??= freshMonitor();
    return { state: { ...state, monitors }, effects: [] };
  },
  Hover(state, { monitor, on }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: withMonitor(state, monitor, { hovered: on }),
      effects: [],
    };
  },
  ExpandedToggle(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: withMonitor(state, monitor, {
        pinned: !state.monitors[monitor].pinned,
      }),
      effects: [],
    };
  },
  LauncherToggle(state, { monitor, sub = null }) {
    const { keyboard } = state.global;
    if (keyboard?.owner === monitor) {
      return keyboard.kind === "launcher"
        ? setGlobal(state, { keyboard: null })
        : unchanged(state);
    }
    return openKeyboard(state, monitor, "launcher", sub);
  },
  PowerOpen(state, { monitor, action = null }) {
    return openKeyboard(state, monitor, "power", action);
  },
  Close(state, { monitor }) {
    return state.global.keyboard?.owner === monitor
      ? setGlobal(state, { keyboard: null })
      : unchanged(state);
  },
  ToastShown(state, { id, critical }) {
    return setGlobal(state, { toast: { id, critical, phase: "shown" } });
  },
  ToastTimeout(state, { id }) {
    const { toast } = state.global;
    if (toast?.id !== id || toast.phase !== "shown") return unchanged(state);
    return setGlobal(state, {
      toast: toast.critical ? { ...toast, phase: "indicator" } : null,
    });
  },
  ToastDismissed(state, { id }) {
    return state.global.toast?.id === id
      ? setGlobal(state, { toast: null })
      : unchanged(state);
  },
};

export function reduce(state, event) {
  const handler = handlers[event.type];
  return handler ? handler(state, event) : unchanged(state);
}
