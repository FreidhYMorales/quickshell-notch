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
};

export function reduce(state, event) {
  const handler = handlers[event.type];
  return handler ? handler(state, event) : { state, effects: [] };
}
