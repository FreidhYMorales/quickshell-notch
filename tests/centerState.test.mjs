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
