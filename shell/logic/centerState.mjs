// Pure reducer for the centre notch. No Qt imports, no I/O, no timers.
// reduce(state, event) -> { state, effects }

import { ACTIONS, needsHold } from "./powerMenu.mjs";

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

// Qt's V4 engine has no object spread: shallow-merge with Object.assign.
const merge = (...parts) => Object.assign({}, ...parts);

const withMonitor = (state, name, patch) =>
  merge(state, {
    monitors: merge(state.monitors, {
      [name]: merge(state.monitors[name], patch),
    }),
  });

const unchanged = (state) => ({ state, effects: [] });

// The calendar slice lives on a monitor only while it differs from the week
// centred on today, so an untouched monitor keeps its plain shape.
const withoutCalendar = (state, name) => {
  const monitor = {};
  for (const key in state.monitors[name]) {
    if (key !== "calendar") monitor[key] = state.monitors[name][key];
  }
  return merge(state, {
    monitors: merge(state.monitors, { [name]: monitor }),
  });
};

const withoutKeyboardFocus = (state, name) => {
  const monitor = {};
  for (const key in state.monitors[name]) {
    if (key !== "keyboardFocus") monitor[key] = state.monitors[name][key];
  }
  return merge(state, {
    monitors: merge(state.monitors, { [name]: monitor }),
  });
};

// Once the expanded notch closes (neither hovered nor pinned) a browsed date
// or an open month is forgotten: it reopens on the week around today.
const closeCalendar = (state, name) => {
  const monitor = state.monitors[name];
  return monitor.calendar && !monitor.hovered && !monitor.pinned
    ? withoutCalendar(state, name)
    : state;
};

const setGlobal = (state, patch) => ({
  state: merge(state, { global: merge(state.global, patch) }),
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
    ? setGlobal(state, { keyboard: merge(state.global.keyboard, { hold }) })
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
      state: merge(state, {
        monitors,
        global: merge(state.global, {
          keyboard: lostKeyboard ? null : keyboard,
          polkit: lostPolkit ? null : polkit,
        }),
      }),
      effects: lostPolkit ? cancelPolkit(polkit) : [],
    };
  },
  Hover(state, { monitor, on }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: closeCalendar(
        withMonitor(state, monitor, { hovered: on }),
        monitor,
      ),
      effects: [],
    };
  },
  ExpandedToggle(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    const pinned = !state.monitors[monitor].pinned;
    const toggled = withMonitor(state, monitor, { pinned });
    const focused = pinned
      ? withMonitor(toggled, monitor, { keyboardFocus: true })
      : withoutKeyboardFocus(toggled, monitor);
    return {
      state: closeCalendar(
        focused,
        monitor,
      ),
      effects: [],
    };
  },
  ExpandedClose(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    const closed = withMonitor(state, monitor, {
      hovered: false,
      pinned: false,
      calendar: null,
    });
    return {
      state: withoutKeyboardFocus(closed, monitor),
      effects: [],
    };
  },
  CalendarMonth(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: withMonitor(state, monitor, {
        calendar: { view: "month", offset: 0 },
      }),
      effects: [],
    };
  },
  CalendarOpen(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return setGlobal(
      withMonitor(state, monitor, {
        pinned: true,
        keyboardFocus: true,
        calendar: { view: "month", offset: 0 },
      }),
      { keyboard: null },
    );
  },
  CalendarToggle(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    if (state.monitors[monitor].calendar?.view === "month") {
      const closed = withMonitor(state, monitor, {
        hovered: false,
        pinned: false,
        calendar: null,
      });
      return {
        state: withoutKeyboardFocus(closed, monitor),
        effects: [],
      };
    }
    return handlers.CalendarOpen(state, { monitor });
  },
  CalendarBack(state, { monitor }) {
    if (!state.monitors[monitor]) return unchanged(state);
    return {
      state: withoutCalendar(
        withMonitor(state, monitor, { keyboardFocus: true }),
        monitor,
      ),
      effects: [],
    };
  },
  // Weeks in the week strip, months in the month grid; positive is later.
  CalendarScroll(state, { monitor, steps }) {
    if (!state.monitors[monitor]) return unchanged(state);
    const calendar = state.monitors[monitor].calendar ??
      { view: "week", offset: 0 };
    const offset = calendar.offset + steps;
    // A week strip back on today is the plain monitor again.
    if (calendar.view === "week" && offset === 0) {
      return { state: withoutCalendar(state, monitor), effects: [] };
    }
    return {
      state: withMonitor(state, monitor, {
        calendar: { view: calendar.view, offset },
      }),
      effects: [],
    };
  },
  CalendarToday(state, { monitor }) {
    const calendar = state.monitors[monitor]?.calendar;
    if (!calendar) return unchanged(state);
    return calendar.view === "month"
      ? {
        state: withMonitor(state, monitor, {
          calendar: { view: "month", offset: 0 },
        }),
        effects: [],
      }
      : { state: withoutCalendar(state, monitor), effects: [] };
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
  WallpaperOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "wallpaper") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "wallpaper" }),
    });
  },
  WallpaperBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "wallpaper") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  ThemeOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "theme") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "theme" }),
    });
  },
  ThemeBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "theme") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  KeybindsOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "keybinds") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "keybinds" }),
    });
  },
  KeybindsBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "keybinds") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  WebappOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "webapp") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "webapp" }),
    });
  },
  WebappBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "webapp") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  ScreensaverOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "screensaver") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "screensaver" }),
    });
  },
  ScreensaverBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "screensaver") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  SecurityOpen(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub === "security") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: "security" }),
    });
  },
  SecurityBack(state) {
    const keyboard = state.global.keyboard;
    if (keyboard?.kind !== "launcher" || keyboard.sub !== "security") {
      return unchanged(state);
    }
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: null }),
    });
  },
  LauncherQuery(state, { text }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "launcher") return unchanged(state);
    return setGlobal(state, {
      keyboard: merge(keyboard, { query: text, index: 0 }),
    });
  },
  // The store passes `count` (results shown); the reducer never sees the apps.
  LauncherMove(state, { step, count }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "launcher") return unchanged(state);
    const to = Math.min(count - 1, (keyboard.index ?? 0) + step);
    return setGlobal(state, {
      keyboard: merge(keyboard, { index: Math.max(0, to) }),
    });
  },
  LauncherSelect(state, { index }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "launcher") return unchanged(state);
    return setGlobal(state, { keyboard: merge(keyboard, { index }) });
  },
  // The store resolves the selected (or clicked) result to `appId`; null means
  // there are no results.
  LauncherActivate(state, { appId }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "launcher" || !appId) return unchanged(state);
    return {
      state: setGlobal(state, { keyboard: null }).state,
      effects: [{ type: "app.launch", appId }],
    };
  },
  PowerOpen(state, { monitor, action = null }) {
    return openKeyboard(state, monitor, "power", action);
  },
  PowerMove(state, { step }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "power") return unchanged(state);
    const from = Math.max(0, ACTIONS.indexOf(keyboard.sub));
    const to = Math.min(ACTIONS.length - 1, Math.max(0, from + step));
    return setGlobal(state, {
      keyboard: merge(keyboard, { sub: ACTIONS[to] }),
    });
  },
  PowerSelect(state, { action }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "power" || !ACTIONS.includes(action)) {
      return unchanged(state);
    }
    return setGlobal(state, { keyboard: merge(keyboard, { sub: action }) });
  },
  // Lock and suspend fire at once and close the menu; the rest need a hold.
  PowerActivate(state, { action = null }) {
    const { keyboard } = state.global;
    if (keyboard?.kind !== "power") return unchanged(state);
    const chosen = action ?? keyboard.sub ?? ACTIONS[0];
    if (needsHold(chosen)) return unchanged(state);
    return {
      state: setGlobal(state, { keyboard: null }).state,
      effects: [{ type: "power.run", action: chosen }],
    };
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
  // Key auto-repeat sends more starts: an existing hold is left untouched.
  HoldStart(state, { action }) {
    const { keyboard, polkit } = state.global;
    if (keyboard?.kind !== "power" || polkit || keyboard.hold) {
      return unchanged(state);
    }
    return needsHold(action) ? withHold(state, { action }) : unchanged(state);
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
      return { state, effects: [{ type: "polkit.cancel", flowId }] };
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
      state: merge(state, {
        monitors,
        global: merge(state.global, {
          locked: true,
          keyboard: null,
          polkit: null,
        }),
      }),
      effects: cancelPolkit(state.global.polkit),
    };
  },
  ToastShown(state, { id, critical }) {
    if (suppressed(state.global, critical)) {
      // A muted critical toast must not be lost: it waits as the `!` indicator.
      // A muted normal one is skipped, so it never shows once the mute lifts.
      return {
        state: setGlobal(
          state,
          merge(
            { blinkDot: true },
            critical ? { toast: { id, critical, phase: "indicator" } } : {},
          ),
        ).state,
        effects: critical ? [] : [{ type: "toast.skip", id }],
      };
    }
    return setGlobal(state, { toast: { id, critical, phase: "shown" } });
  },
  ToastTimeout(state, { id }) {
    const { toast } = state.global;
    if (toast?.id !== id || toast.phase !== "shown") return unchanged(state);
    return setGlobal(state, {
      toast: toast.critical ? merge(toast, { phase: "indicator" }) : null,
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
