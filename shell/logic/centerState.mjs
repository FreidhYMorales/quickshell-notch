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

const setKeyboard = (state, keyboard) => ({
  state: { ...state, global: { ...state.global, keyboard } },
  effects: [],
});

// Opens or replaces the keyboard slot. Only the current owner (or anyone, when
// the slot is empty) may change it; unknown monitors are ignored.
const openKeyboard = (state, monitor, kind, sub) => {
  const { keyboard } = state.global;
  if (!state.monitors[monitor]) return unchanged(state);
  if (keyboard && keyboard.owner !== monitor) return unchanged(state);
  return setKeyboard(state, { owner: monitor, kind, sub, hold: null });
};

const handlers = {
  ScreensChanged(state, { names }) {
    const monitors = { ...state.monitors };
    for (const name of names) monitors[name] ??= freshMonitor();
    return { state: { ...state, monitors }, effects: [] };
  },
  Hover(state, { monitor, on }) {
    if (!state.monitors[monitor]) return { state, effects: [] };
    return {
      state: withMonitor(state, monitor, { hovered: on }),
      effects: [],
    };
  },
  ExpandedToggle(state, { monitor }) {
    if (!state.monitors[monitor]) return { state, effects: [] };
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
        ? setKeyboard(state, null)
        : unchanged(state);
    }
    return openKeyboard(state, monitor, "launcher", sub);
  },
  PowerOpen(state, { monitor, action = null }) {
    return openKeyboard(state, monitor, "power", action);
  },
  Close(state, { monitor }) {
    return state.global.keyboard?.owner === monitor
      ? setKeyboard(state, null)
      : unchanged(state);
  },
};

export function reduce(state, event) {
  const handler = handlers[event.type];
  return handler ? handler(state, event) : { state, effects: [] };
}
