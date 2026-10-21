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
