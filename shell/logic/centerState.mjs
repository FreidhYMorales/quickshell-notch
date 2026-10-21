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
  const { keyboard, locked } = state.global;
  if (locked || !state.monitors[monitor]) return unchanged(state);
  if (keyboard && keyboard.owner !== monitor) return unchanged(state);
  return setGlobal(state, {
    keyboard: { owner: monitor, kind, sub, hold: null },
  });
};

const cancelPolkit = (polkit) =>
  polkit ? [{ type: "polkit.cancel", flowId: polkit.flowId }] : [];

// Any open keyboard state or polkit flow mutes toasts on every monitor.
const suppressed = ({ dnd, keyboard, polkit }, critical) =>
  keyboard !== null || polkit !== null || (dnd && !critical);

const withHold = (state, hold) =>
  state.global.keyboard
    ? setGlobal(state, { keyboard: { ...state.global.keyboard, hold } })
    : unchanged(state);

const handlers = {
  ScreensChanged(state, { names }) {
    const monitors = {};
    for (const name of names) {
      monitors[name] = state.monitors[name] ?? freshMonitor();
    }
    const { keyboard, polkit } = state.global;
    const lostKeyboard = keyboard && !monitors[keyboard.owner];
    const lostPolkit = polkit && !monitors[polkit.owner];
    return {
      state: {
        ...state,
        monitors,
        global: {
          ...state.global,
          keyboard: lostKeyboard ? null : keyboard,
          polkit: lostPolkit ? null : polkit,
        },
      },
      effects: lostPolkit ? cancelPolkit(polkit) : [],
    };
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
  ToastHover(state, { monitor, on }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: withMonitor(state, monitor, { toastHovered: on }),
      effects: [],
    };
  },
  Dnd(state, { on }) {
    return setGlobal(state, { dnd: on });
  },
  HoldStart(state, { action }) {
    return state.global.keyboard?.kind === "power" && !state.global.polkit
      ? withHold(state, { action })
      : unchanged(state);
  },
  HoldCancel(state) {
    return withHold(state, null);
  },
  HoldComplete(state) {
    const hold = state.global.keyboard?.hold;
    if (!hold) return unchanged(state);
    return {
      state: withHold(state, null).state,
      effects: [{ type: "power.run", action: hold.action }],
    };
  },
  PolkitRequest(state, { flowId, monitor }) {
    if (state.global.locked || !state.monitors[monitor]) {
      return unchanged(state);
    }
    const cleared = withHold(state, null).state;
    return setGlobal(cleared, { polkit: { flowId, owner: monitor } });
  },
  PolkitEnded(state, { flowId }) {
    return state.global.polkit?.flowId === flowId
      ? setGlobal(state, { polkit: null })
      : unchanged(state);
  },
  PolkitCancel(state) {
    const { polkit } = state.global;
    if (!polkit) return unchanged(state);
    return {
      state: setGlobal(state, { polkit: null }).state,
      effects: cancelPolkit(polkit),
    };
  },
  Locked(state, { on }) {
    if (!on) return setGlobal(state, { locked: false });
    const monitors = {};
    for (const name of Object.keys(state.monitors)) {
      monitors[name] = freshMonitor();
    }
    return {
      state: {
        ...state,
        monitors,
        global: {
          ...state.global,
          locked: true,
          keyboard: null,
          polkit: null,
        },
      },
      effects: cancelPolkit(state.global.polkit),
    };
  },
  ToastShown(state, { id, critical }) {
    if (suppressed(state.global, critical)) {
      // A muted critical toast must not be lost: it waits as the `!` indicator.
      return setGlobal(state, {
        blinkDot: true,
        ...(critical && { toast: { id, critical, phase: "indicator" } }),
      });
    }
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
