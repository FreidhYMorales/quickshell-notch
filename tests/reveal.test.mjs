import { test } from "node:test";
import assert from "node:assert/strict";
import {
  initialReveal,
  isVisible,
  stepReveal,
} from "../shell/logic/reveal.mjs";

// run(events) -> { state, timers } folding stepReveal from the initial state.
const run = (events, from = initialReveal()) => {
  let state = from;
  const timers = [];
  for (const ev of events) {
    const r = stepReveal(state, ev);
    state = r.state;
    timers.push(r.timer);
  }
  return { state, timers };
};
const ready = [{ type: "Ready" }];

test("initial state is closed, unready and not visible", () => {
  const s = initialReveal();
  assert.deepEqual(s, {
    ready: false,
    open: false,
    hover: false,
    hold: false,
    pinned: false,
    flash: null,
  });
  assert.equal(isVisible(s), false);
});

test("startup gate: a Trigger before Ready leaves the state unchanged", () => {
  const before = initialReveal();
  const r = stepReveal(before, { type: "Trigger" });
  assert.deepEqual(r.state, before);
  assert.equal(r.timer, "none");
});

test("startup gate: Ready alone does not reveal; a Trigger after it does", () => {
  const a = run(ready);
  assert.equal(a.state.ready, true);
  assert.equal(isVisible(a.state), false);
  assert.deepEqual(a.timers, ["none"]);
  const b = run([{ type: "Trigger" }], a.state);
  assert.equal(isVisible(b.state), true);
  assert.deepEqual(b.timers, ["restart"]);
});

// Spec transition table, one row per case.
const table = [
  [
    "hidden + trigger -> visible, timer start",
    [],
    ["Trigger"],
    true,
    "restart",
  ],
  [
    "visible + trigger -> visible, timer restart",
    ["Trigger"],
    ["Trigger"],
    true,
    "restart",
  ],
  ["visible + timeout -> hidden", ["Trigger"], ["Timeout"], false, "none"],
  [
    "visible + hover enter -> held, timer stop",
    ["Trigger"],
    [
      { type: "Hover", on: true },
    ],
    true,
    "stop",
  ],
  [
    "held + hover leave -> visible, timer restart",
    ["Trigger", { type: "Hover", on: true }],
    [{ type: "Hover", on: false }],
    true,
    "restart",
  ],
  [
    "held (hover) + timeout -> held",
    ["Trigger", { type: "Hover", on: true }],
    ["Timeout"],
    true,
    "none",
  ],
  [
    "visible + drag start -> held",
    ["Trigger"],
    [{ type: "Hold", on: true }],
    true,
    "stop",
  ],
  [
    "held (drag) + drag end -> visible, timer restart",
    ["Trigger", { type: "Hold", on: true }],
    [{ type: "Hold", on: false }],
    true,
    "restart",
  ],
  [
    "held + trigger -> stays open, timer stays stopped",
    ["Trigger", { type: "Hover", on: true }],
    ["Trigger"],
    true,
    "stop",
  ],
  [
    "hover leave while still dragging keeps the hold",
    ["Trigger", { type: "Hover", on: true }, { type: "Hold", on: true }],
    [{ type: "Hover", on: false }],
    true,
    "none",
  ],
  [
    "hover enter on a hidden surface is ignored",
    [],
    [{ type: "Hover", on: true }],
    false,
    "none",
  ],
  ["timeout while hidden stays hidden", [], ["Timeout"], false, "none"],
];
const ev = (e) => (typeof e === "string" ? { type: e } : e);
for (const [name, setup, steps, visible, timer] of table) {
  test(`transition: ${name}`, () => {
    const from = run(ready.concat(setup.map(ev))).state;
    const r = run(steps.map(ev), from);
    assert.equal(isVisible(r.state), visible);
    assert.equal(r.timers[r.timers.length - 1], timer);
  });
}

test("timeout clears the flash; hover leave afterwards does not reopen", () => {
  const open = run(ready.concat([{ type: "Trigger", flash: { id: 3 } }])).state;
  assert.deepEqual(open.flash, { id: 3 });
  const gone = run([{ type: "Timeout" }], open).state;
  assert.equal(gone.flash, null);
  assert.equal(stepReveal(gone, { type: "Hover", on: false }).timer, "none");
});

test("a Trigger without flash keeps the current flash; a new flash replaces it", () => {
  const a = run(ready.concat([{ type: "Trigger", flash: { id: 1 } }]));
  const b = run([{ type: "Trigger" }], a.state);
  assert.deepEqual(b.state.flash, { id: 1 });
  const c = run([{ type: "Trigger", flash: { id: 2 } }], b.state);
  assert.deepEqual(c.state.flash, { id: 2 });
});

test("pin: visible with no timer, even when never opened", () => {
  const r = run(ready.concat([{ type: "Pin", on: true }]));
  assert.equal(isVisible(r.state), true);
  assert.equal(r.timers[1], "stop");
});

test("pin: timeout and triggers do not hide or time out a pinned surface", () => {
  const s = run(ready.concat([{ type: "Pin", on: true }, "Trigger"].map(ev)))
    .state;
  const t = stepReveal(s, { type: "Timeout" });
  assert.equal(isVisible(t.state), true);
  assert.equal(t.timer, "none");
});

test("unpin: stays revealed and the hide timer starts", () => {
  const s = run(ready.concat([{ type: "Pin", on: true }])).state;
  const r = stepReveal(s, { type: "Pin", on: false });
  assert.equal(r.state.pinned, false);
  assert.equal(isVisible(r.state), true);
  assert.equal(r.timer, "restart");
  const hidden = stepReveal(r.state, { type: "Timeout" });
  assert.equal(isVisible(hidden.state), false);
});

test("unpin while hovered keeps the timer stopped", () => {
  const s = run(ready.concat([
    { type: "Pin", on: true },
    { type: "Hover", on: true },
  ])).state;
  assert.equal(stepReveal(s, { type: "Pin", on: false }).timer, "stop");
});

test("pin applies before Ready (a special already active at startup)", () => {
  const r = stepReveal(initialReveal(), { type: "Pin", on: true });
  assert.equal(isVisible(r.state), true);
});

test("unknown events leave the state unchanged and never mutate input", () => {
  const s = Object.freeze(run(ready).state);
  const r = stepReveal(s, { type: "Nope" });
  assert.equal(r.state, s);
  assert.equal(r.timer, "none");
});
