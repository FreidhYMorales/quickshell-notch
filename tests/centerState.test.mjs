import { test } from "node:test";
import assert from "node:assert/strict";
import { initialState, reduce } from "../shell/logic/centerState.mjs";

const two = () => initialState(["A", "B"]);

test("initialState: idle global slots and one slice per monitor", () => {
  assert.deepEqual(two(), {
    global: {
      locked: false,
      dnd: false,
      blinkDot: false,
      toast: null,
      keyboard: null,
      polkit: null,
    },
    monitors: {
      A: { hovered: false, pinned: false, toastHovered: false },
      B: { hovered: false, pinned: false, toastHovered: false },
    },
  });
});

test("initialState: no monitors gives an empty monitors map", () => {
  assert.deepEqual(initialState([]).monitors, {});
});

test("purity: reduce does not mutate its input and is deterministic", () => {
  const s = two();
  const frozen = structuredClone(s);
  const ev = { type: "Hover", monitor: "A", on: true };
  const r1 = reduce(s, ev);
  const r2 = reduce(s, ev);
  assert.deepEqual(s, frozen);
  assert.deepEqual(r1, r2);
  assert.notEqual(r1.state, s);
});

test("Hover: enter on A leaves B untouched", () => {
  const { state, effects } = reduce(two(), {
    type: "Hover",
    monitor: "A",
    on: true,
  });
  assert.equal(state.monitors.A.hovered, true);
  assert.equal(state.monitors.B.hovered, false);
  assert.deepEqual(effects, []);
});

test("Hover: leave clears A", () => {
  const entered = reduce(two(), { type: "Hover", monitor: "A", on: true });
  const { state } = reduce(entered.state, {
    type: "Hover",
    monitor: "A",
    on: false,
  });
  assert.equal(state.monitors.A.hovered, false);
});

test("Hover: unknown monitor is ignored", () => {
  const s = two();
  const { state } = reduce(s, { type: "Hover", monitor: "Z", on: true });
  assert.deepEqual(state, s);
});

test("ExpandedToggle: toggles pinned on one monitor only", () => {
  const on = reduce(two(), { type: "ExpandedToggle", monitor: "A" });
  assert.equal(on.state.monitors.A.pinned, true);
  assert.equal(on.state.monitors.B.pinned, false);
  const off = reduce(on.state, { type: "ExpandedToggle", monitor: "A" });
  assert.equal(off.state.monitors.A.pinned, false);
});

test("ScreensChanged: adds new monitors and keeps existing slices", () => {
  const hovered = reduce(two(), { type: "Hover", monitor: "A", on: true });
  const { state } = reduce(hovered.state, {
    type: "ScreensChanged",
    names: ["A", "B", "C"],
  });
  assert.equal(state.monitors.A.hovered, true);
  assert.deepEqual(state.monitors.C, {
    hovered: false,
    pinned: false,
    toastHovered: false,
  });
});

test("unknown event returns the state unchanged with no effects", () => {
  const s = two();
  const { state, effects } = reduce(s, { type: "Nope" });
  assert.deepEqual(state, s);
  assert.deepEqual(effects, []);
});

const run = (state, ...events) =>
  events.reduce((s, ev) => reduce(s, ev).state, state);

test("LauncherToggle: opens the launcher on the requesting monitor", () => {
  const { state, effects } = reduce(two(), {
    type: "LauncherToggle",
    monitor: "A",
    sub: "apps",
  });
  assert.deepEqual(state.global.keyboard, {
    owner: "A",
    kind: "launcher",
    sub: "apps",
    hold: null,
  });
  assert.deepEqual(effects, []);
});

test("LauncherToggle: a second toggle on the owner closes it", () => {
  const s = run(
    two(),
    { type: "LauncherToggle", monitor: "A", sub: "apps" },
    { type: "LauncherToggle", monitor: "A", sub: "apps" },
  );
  assert.equal(s.global.keyboard, null);
});

test("LauncherToggle: sub defaults to null", () => {
  const s = run(two(), { type: "LauncherToggle", monitor: "B" });
  assert.equal(s.global.keyboard.sub, null);
  assert.equal(s.global.keyboard.owner, "B");
});

test("PowerOpen: opens the power menu with an optional action", () => {
  const plain = run(two(), { type: "PowerOpen", monitor: "A" });
  assert.deepEqual(plain.global.keyboard, {
    owner: "A",
    kind: "power",
    sub: null,
    hold: null,
  });
  const withAction = run(two(), {
    type: "PowerOpen",
    monitor: "A",
    action: "reboot",
  });
  assert.equal(withAction.global.keyboard.sub, "reboot");
});

test("PowerOpen: replaces the launcher on the owner and keeps the owner", () => {
  const s = run(
    two(),
    { type: "LauncherToggle", monitor: "A", sub: "apps" },
    { type: "PowerOpen", monitor: "A" },
  );
  assert.equal(s.global.keyboard.kind, "power");
  assert.equal(s.global.keyboard.owner, "A");
});

test("LauncherToggle: ignored while the power menu is open", () => {
  const s = run(
    two(),
    { type: "PowerOpen", monitor: "A" },
    { type: "LauncherToggle", monitor: "A", sub: "apps" },
  );
  assert.equal(s.global.keyboard.kind, "power");
});

test("Close: owner closes the keyboard slot", () => {
  const s = run(
    two(),
    { type: "LauncherToggle", monitor: "A", sub: "apps" },
    { type: "Close", monitor: "A" },
  );
  assert.equal(s.global.keyboard, null);
});

test("Close: non-owner and closed slot are no-ops", () => {
  const open = run(two(), { type: "PowerOpen", monitor: "A" });
  assert.deepEqual(run(open, { type: "Close", monitor: "B" }), open);
  const closed = two();
  assert.deepEqual(run(closed, { type: "Close", monitor: "A" }), closed);
});

test("keyboard owner: an open on another monitor leaves the owner unchanged", () => {
  const open = run(two(), { type: "LauncherToggle", monitor: "A", sub: "x" });
  const afterLauncher = run(open, {
    type: "LauncherToggle",
    monitor: "B",
    sub: "y",
  });
  assert.deepEqual(afterLauncher.global.keyboard, open.global.keyboard);
  const afterPower = run(open, { type: "PowerOpen", monitor: "B" });
  assert.deepEqual(afterPower.global.keyboard, open.global.keyboard);
});

test("keyboard: opens on an unknown monitor are ignored", () => {
  const s = run(two(), { type: "LauncherToggle", monitor: "Z", sub: "x" });
  assert.equal(s.global.keyboard, null);
});

test("ToastShown: stores a normal toast in the shown phase", () => {
  const { state, effects } = reduce(two(), {
    type: "ToastShown",
    id: 1,
    critical: false,
  });
  assert.deepEqual(state.global.toast, {
    id: 1,
    critical: false,
    phase: "shown",
  });
  assert.deepEqual(effects, []);
});

test("ToastShown: a newer toast replaces the current one", () => {
  const s = run(
    two(),
    { type: "ToastShown", id: 1, critical: false },
    { type: "ToastShown", id: 2, critical: true },
  );
  assert.deepEqual(s.global.toast, { id: 2, critical: true, phase: "shown" });
});

test("ToastTimeout: a normal toast is cleared", () => {
  const s = run(
    two(),
    { type: "ToastShown", id: 1, critical: false },
    { type: "ToastTimeout", id: 1 },
  );
  assert.equal(s.global.toast, null);
});

test("ToastTimeout: a critical toast collapses to the indicator phase", () => {
  const s = run(
    two(),
    { type: "ToastShown", id: 1, critical: true },
    { type: "ToastTimeout", id: 1 },
  );
  assert.deepEqual(s.global.toast, {
    id: 1,
    critical: true,
    phase: "indicator",
  });
});

test("ToastTimeout: a stale id or an already collapsed toast is ignored", () => {
  const shown = run(two(), { type: "ToastShown", id: 2, critical: false });
  assert.deepEqual(run(shown, { type: "ToastTimeout", id: 1 }), shown);
  const collapsed = run(
    two(),
    { type: "ToastShown", id: 1, critical: true },
    { type: "ToastTimeout", id: 1 },
  );
  assert.deepEqual(run(collapsed, { type: "ToastTimeout", id: 1 }), collapsed);
});

test("ToastDismissed: clears a shown or collapsed toast with that id", () => {
  const shown = run(
    two(),
    { type: "ToastShown", id: 1, critical: false },
    { type: "ToastDismissed", id: 1 },
  );
  assert.equal(shown.global.toast, null);
  const indicator = run(
    two(),
    { type: "ToastShown", id: 1, critical: true },
    { type: "ToastTimeout", id: 1 },
    { type: "ToastDismissed", id: 1 },
  );
  assert.equal(indicator.global.toast, null);
});

test("ToastDismissed: a different id leaves the toast alone", () => {
  const shown = run(two(), { type: "ToastShown", id: 1, critical: false });
  assert.deepEqual(run(shown, { type: "ToastDismissed", id: 9 }), shown);
});

// --- Mid-flow rules (PR 2) ---

const play = (events, start = two()) => {
  let state = start;
  const effects = [];
  for (const ev of events) {
    const r = reduce(state, ev);
    state = r.state;
    effects.push(...r.effects);
  }
  return { state, effects };
};

test("PolkitRequest: stores the flow on the requesting monitor", () => {
  const { state } = play([{
    type: "PolkitRequest",
    flowId: "f1",
    monitor: "A",
  }]);
  assert.deepEqual(state.global.polkit, { flowId: "f1", owner: "A" });
});

test("PolkitRequest: clears an in-progress power hold", () => {
  const { state } = play([
    { type: "PowerOpen", monitor: "A", action: "poweroff" },
    { type: "HoldStart", action: "poweroff" },
    { type: "PolkitRequest", flowId: "f1", monitor: "A" },
  ]);
  assert.equal(state.global.keyboard.hold, null);
  assert.equal(state.global.polkit.flowId, "f1");
});

test("PolkitRequest: unknown monitor is ignored", () => {
  const { state } = play([{
    type: "PolkitRequest",
    flowId: "f1",
    monitor: "Z",
  }]);
  assert.equal(state.global.polkit, null);
});

test("PolkitEnded: matching flow clears, other flow does not", () => {
  const open = [{ type: "PolkitRequest", flowId: "f1", monitor: "A" }];
  assert.equal(
    play([...open, { type: "PolkitEnded", flowId: "f1" }]).state.global.polkit,
    null,
  );
  assert.equal(
    play([...open, { type: "PolkitEnded", flowId: "other" }]).state.global
      .polkit.flowId,
    "f1",
  );
});

test("PolkitCancel: clears the flow and emits polkit.cancel", () => {
  const { state, effects } = play([
    { type: "PolkitRequest", flowId: "f1", monitor: "A" },
    { type: "PolkitCancel" },
  ]);
  assert.equal(state.global.polkit, null);
  assert.deepEqual(effects, [{ type: "polkit.cancel", flowId: "f1" }]);
});

test("PolkitCancel: without a flow does nothing", () => {
  const { state, effects } = play([{ type: "PolkitCancel" }]);
  assert.deepEqual(state, two());
  assert.deepEqual(effects, []);
});

test("Hold: start sets the hold, cancel clears it", () => {
  const open = { type: "PowerOpen", monitor: "A", action: "poweroff" };
  const held = play([open, { type: "HoldStart", action: "poweroff" }]);
  assert.deepEqual(held.state.global.keyboard.hold, { action: "poweroff" });
  const cancelled = play([open, { type: "HoldStart", action: "poweroff" }, {
    type: "HoldCancel",
  }]);
  assert.equal(cancelled.state.global.keyboard.hold, null);
  assert.deepEqual(cancelled.effects, []);
});

test("Hold: start without a power menu is ignored", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "HoldStart", action: "poweroff" },
  ]);
  assert.equal(state.global.keyboard.hold, null);
});

test("HoldComplete: emits power.run and clears the hold", () => {
  const { state, effects } = play([
    { type: "PowerOpen", monitor: "A", action: "reboot" },
    { type: "HoldStart", action: "reboot" },
    { type: "HoldComplete" },
  ]);
  assert.deepEqual(effects, [{ type: "power.run", action: "reboot" }]);
  assert.equal(state.global.keyboard.hold, null);
});

test("HoldComplete: without a hold emits nothing", () => {
  const { effects } = play([
    { type: "PowerOpen", monitor: "A", action: "reboot" },
    { type: "HoldComplete" },
  ]);
  assert.deepEqual(effects, []);
});

const busy = [
  { type: "Hover", monitor: "A", on: true },
  { type: "ExpandedToggle", monitor: "B" },
  { type: "PowerOpen", monitor: "A", action: "poweroff" },
  { type: "PolkitRequest", flowId: "f1", monitor: "A" },
];

test("Locked on: closes everything and emits polkit.cancel", () => {
  const { state, effects } = play([...busy, { type: "Locked", on: true }]);
  assert.equal(state.global.locked, true);
  assert.equal(state.global.keyboard, null);
  assert.equal(state.global.polkit, null);
  assert.deepEqual(state.monitors.A, {
    hovered: false,
    pinned: false,
    toastHovered: false,
  });
  assert.equal(state.monitors.B.pinned, false);
  assert.deepEqual(effects, [{ type: "polkit.cancel", flowId: "f1" }]);
});

test("Locked on: no polkit means no effect", () => {
  const { effects } = play([{ type: "Locked", on: true }]);
  assert.deepEqual(effects, []);
});

test("Locked: keyboard and polkit opens are ignored until unlock", () => {
  const locked = { type: "Locked", on: true };
  const opens = [
    { type: "LauncherToggle", monitor: "A" },
    { type: "PowerOpen", monitor: "A" },
    { type: "PolkitRequest", flowId: "f2", monitor: "A" },
  ];
  const during = play([locked, ...opens]).state.global;
  assert.equal(during.keyboard, null);
  assert.equal(during.polkit, null);
  const after = play([locked, { type: "Locked", on: false }, opens[0]]).state
    .global;
  assert.equal(after.locked, false);
  assert.equal(after.keyboard.kind, "launcher");
});

test("ScreensChanged: removing the keyboard owner closes the keyboard", () => {
  const { state, effects } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "ScreensChanged", names: ["B"] },
  ]);
  assert.deepEqual(Object.keys(state.monitors), ["B"]);
  assert.equal(state.global.keyboard, null);
  assert.deepEqual(effects, []);
});

test("ScreensChanged: removing the polkit owner cancels the flow", () => {
  const { state, effects } = play([
    { type: "PolkitRequest", flowId: "f1", monitor: "A" },
    { type: "ScreensChanged", names: ["B"] },
  ]);
  assert.equal(state.global.polkit, null);
  assert.deepEqual(effects, [{ type: "polkit.cancel", flowId: "f1" }]);
});

test("ScreensChanged: removing another monitor is harmless", () => {
  const { state, effects } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "ScreensChanged", names: ["A"] },
  ]);
  assert.deepEqual(Object.keys(state.monitors), ["A"]);
  assert.equal(state.global.keyboard.owner, "A");
  assert.deepEqual(effects, []);
});

test("Dnd and ToastHover: set their flags", () => {
  const { state } = play([
    { type: "Dnd", on: true },
    { type: "ToastHover", monitor: "B", on: true },
  ]);
  assert.equal(state.global.dnd, true);
  assert.equal(state.monitors.B.toastHovered, true);
  assert.equal(state.monitors.A.toastHovered, false);
});

test("Suppression: DND blocks a normal toast and sets blinkDot", () => {
  const { state } = play([
    { type: "Dnd", on: true },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.equal(state.global.toast, null);
  assert.equal(state.global.blinkDot, true);
});

test("Suppression: critical bypasses DND", () => {
  const { state } = play([
    { type: "Dnd", on: true },
    { type: "ToastShown", id: 1, critical: true },
  ]);
  assert.equal(state.global.toast.id, 1);
  assert.equal(state.global.blinkDot, false);
});

test("Suppression: an open keyboard state mutes toasts on every monitor", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.equal(state.global.toast, null);
  assert.equal(state.global.blinkDot, true);
});

test("Suppression: an open polkit mutes toasts", () => {
  const { state } = play([
    { type: "PolkitRequest", flowId: "f1", monitor: "B" },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.equal(state.global.toast, null);
  assert.equal(state.global.blinkDot, true);
});

test("Suppression: a muted critical toast goes straight to the indicator", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "ToastShown", id: 1, critical: true },
  ]);
  assert.deepEqual(state.global.toast, {
    id: 1,
    critical: true,
    phase: "indicator",
  });
  assert.equal(state.global.blinkDot, true);
});

test("Suppression: polkit also sends a critical toast to the indicator", () => {
  const { state } = play([
    { type: "PolkitRequest", flowId: "f1", monitor: "B" },
    { type: "ToastShown", id: 1, critical: true },
  ]);
  assert.equal(state.global.toast.phase, "indicator");
});

test("Suppression: no DND and nothing open lets the toast through", () => {
  const { state } = play([{ type: "ToastShown", id: 1, critical: false }]);
  assert.equal(state.global.toast.id, 1);
  assert.equal(state.global.blinkDot, false);
});

test("Suppression: a muted normal toast is skipped, never shown later", () => {
  const skip = [{ type: "toast.skip", id: 1 }];
  const dnd = play([
    { type: "Dnd", on: true },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.deepEqual(dnd.effects, skip);
  const launcher = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.deepEqual(launcher.effects, skip);
  const open = play([{ type: "ToastShown", id: 1, critical: false }]);
  assert.deepEqual(open.effects, []);
  const critical = play([
    { type: "Dnd", on: true },
    { type: "LauncherToggle", monitor: "A" },
    { type: "ToastShown", id: 1, critical: true },
  ]);
  assert.deepEqual(critical.effects, []);
});

test("Suppression: once DND is off again, a normal toast shows", () => {
  const { state, effects } = play([
    { type: "Dnd", on: true },
    { type: "Dnd", on: false },
    { type: "ToastShown", id: 1, critical: false },
  ]);
  assert.deepEqual(state.global.toast, {
    id: 1,
    critical: false,
    phase: "shown",
  });
  assert.deepEqual(effects, []);
});

test("PowerMove: moves from the first action when nothing is preselected", () => {
  const { state } = play([
    { type: "PowerOpen", monitor: "A" },
    { type: "PowerMove", step: 1 },
  ]);
  assert.equal(state.global.keyboard.sub, "suspend");
});

test("PowerMove: moves from the preselected action both ways", () => {
  const open = { type: "PowerOpen", monitor: "A", action: "logout" };
  const right = play([open, { type: "PowerMove", step: 1 }]);
  assert.equal(right.state.global.keyboard.sub, "reboot");
  const left = play([open, { type: "PowerMove", step: -1 }]);
  assert.equal(left.state.global.keyboard.sub, "suspend");
});

test("PowerMove: stays put at either end", () => {
  const first = play([
    { type: "PowerOpen", monitor: "A", action: "lock" },
    { type: "PowerMove", step: -1 },
  ]);
  assert.equal(first.state.global.keyboard.sub, "lock");
  const last = play([
    { type: "PowerOpen", monitor: "A", action: "poweroff" },
    { type: "PowerMove", step: 1 },
  ]);
  assert.equal(last.state.global.keyboard.sub, "poweroff");
});

test("PowerMove: ignored while the launcher is open", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "PowerMove", step: 1 },
  ]);
  assert.equal(state.global.keyboard.sub, null);
});

test("PowerActivate: lock runs at once and closes the menu", () => {
  const { state, effects } = play([
    { type: "PowerOpen", monitor: "A" },
    { type: "PowerActivate" },
  ]);
  assert.deepEqual(effects, [{ type: "power.run", action: "lock" }]);
  assert.equal(state.global.keyboard, null);
});

test("PowerActivate: a clicked suspend runs at once and closes the menu", () => {
  const { state, effects } = play([
    { type: "PowerOpen", monitor: "A", action: "reboot" },
    { type: "PowerActivate", action: "suspend" },
  ]);
  assert.deepEqual(effects, [{ type: "power.run", action: "suspend" }]);
  assert.equal(state.global.keyboard, null);
});

test("PowerActivate: a hold action runs nothing and keeps the menu", () => {
  const { state, effects } = play([
    { type: "PowerOpen", monitor: "A", action: "reboot" },
    { type: "PowerActivate" },
  ]);
  assert.deepEqual(effects, []);
  assert.equal(state.global.keyboard.kind, "power");
  assert.equal(state.global.keyboard.sub, "reboot");
});

test("PowerActivate: ignored while the launcher is open", () => {
  const { state, effects } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "PowerActivate", action: "lock" },
  ]);
  assert.deepEqual(effects, []);
  assert.equal(state.global.keyboard.kind, "launcher");
});

test("HoldStart: a repeated start leaves the running hold untouched", () => {
  const first = play([
    { type: "PowerOpen", monitor: "A", action: "reboot" },
    { type: "HoldStart", action: "reboot" },
  ]).state;
  const repeat = reduce(first, { type: "HoldStart", action: "reboot" });
  // Same state object: nothing re-binds, so the hold timer keeps its progress.
  assert.equal(repeat.state, first);
  assert.deepEqual(repeat.effects, []);
});

test("HoldStart: ignored for actions that fire at once", () => {
  for (const action of ["lock", "suspend"]) {
    const { state } = play([
      { type: "PowerOpen", monitor: "A", action },
      { type: "HoldStart", action },
    ]);
    assert.equal(state.global.keyboard.hold, null, action);
  }
});

test("PowerSelect: hovering an action selects it", () => {
  const { state } = play([
    { type: "PowerOpen", monitor: "A" },
    { type: "PowerSelect", action: "reboot" },
  ]);
  assert.equal(state.global.keyboard.sub, "reboot");
});

test("PowerSelect: unknown actions and other keyboard states are ignored", () => {
  const unknown = play([
    { type: "PowerOpen", monitor: "A", action: "logout" },
    { type: "PowerSelect", action: "nope" },
  ]);
  assert.equal(unknown.state.global.keyboard.sub, "logout");
  const launcher = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "PowerSelect", action: "reboot" },
  ]);
  assert.equal(launcher.state.global.keyboard.sub, null);
});

test("LauncherQuery: stores the typed text and selects the first result", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherQuery", text: "fi" },
  ]);
  assert.equal(state.global.keyboard.query, "fi");
  assert.equal(state.global.keyboard.index, 0);
});

test("LauncherQuery: ignored while the power menu is open", () => {
  const { state } = play([
    { type: "PowerOpen", monitor: "A" },
    { type: "LauncherQuery", text: "fi" },
  ]);
  assert.equal(state.global.keyboard.query, undefined);
});

test("LauncherMove: moves the selection within the results", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherMove", step: 1, count: 5 },
    { type: "LauncherMove", step: 1, count: 5 },
  ]);
  assert.equal(state.global.keyboard.index, 2);
});

test("LauncherMove: stays on the first and last result", () => {
  const up = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherMove", step: -1, count: 3 },
  ]);
  assert.equal(up.state.global.keyboard.index, 0);
  const down = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherMove", step: 1, count: 3 },
    { type: "LauncherMove", step: 1, count: 3 },
    { type: "LauncherMove", step: 1, count: 3 },
  ]);
  assert.equal(down.state.global.keyboard.index, 2);
});

test("LauncherQuery: a new query brings a moved selection back to the first result", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherMove", step: 1, count: 4 },
    { type: "LauncherQuery", text: "f" },
  ]);
  assert.equal(state.global.keyboard.index, 0);
});

test("LauncherSelect: hovering a result selects it", () => {
  const { state } = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherSelect", index: 3 },
  ]);
  assert.equal(state.global.keyboard.index, 3);
});

test("LauncherSelect: ignored while the power menu is open", () => {
  const { state } = play([
    { type: "PowerOpen", monitor: "A" },
    { type: "LauncherSelect", index: 3 },
  ]);
  assert.equal(state.global.keyboard.index, undefined);
});
