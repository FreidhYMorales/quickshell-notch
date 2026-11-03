import { test } from "node:test";
import assert from "node:assert/strict";
import { initialState, reduce } from "../shell/logic/centerState.mjs";
import { toastPaused, unreadDot, viewFor } from "../shell/logic/centerView.mjs";

const play = (events) =>
  events.reduce((s, ev) => reduce(s, ev).state, initialState(["A", "B"]));

const hoverA = { type: "Hover", monitor: "A", on: true };
const toast = (id, critical = false) => ({ type: "ToastShown", id, critical });

test("idle: a fresh monitor shows idle with no focus", () => {
  assert.deepEqual(viewFor(play([]), "A"), {
    mode: "idle",
    sub: null,
    hold: null,
    toast: null,
    showCriticalIndicator: false,
    blinkDot: false,
    keyboardFocus: "none",
  });
});

test("expanded: hover or pin lifts idle to expanded, per monitor", () => {
  const s = play([hoverA, { type: "ExpandedToggle", monitor: "B" }]);
  assert.equal(viewFor(s, "A").mode, "expanded");
  assert.equal(viewFor(s, "B").mode, "expanded");
  assert.equal(viewFor(play([hoverA]), "B").mode, "idle");
});

test("toast: preempts expanded and returns to it when the toast ends", () => {
  const shown = play([hoverA, toast(1)]);
  assert.equal(viewFor(shown, "A").mode, "toast");
  assert.equal(viewFor(shown, "B").mode, "toast");
  const ended = reduce(shown, { type: "ToastTimeout", id: 1 }).state;
  assert.equal(viewFor(ended, "A").mode, "expanded");
  assert.equal(viewFor(ended, "B").mode, "idle");
});

test("toast: hover expands the toast and pauses its timeout", () => {
  const view = viewFor(play([toast(1), hoverA]), "A");
  assert.deepEqual(view.toast, {
    id: 1,
    critical: false,
    expanded: true,
    paused: true,
  });
  const other = viewFor(play([toast(1), hoverA]), "B");
  assert.deepEqual(other.toast, {
    id: 1,
    critical: false,
    expanded: false,
    paused: false,
  });
});

test("toast: toast hover alone pauses without expanding", () => {
  const s = play([toast(1), { type: "ToastHover", monitor: "A", on: true }]);
  const view = viewFor(s, "A");
  assert.equal(view.toast.paused, true);
  assert.equal(view.toast.expanded, false);
});

test("critical: collapses to an indicator and reaches expanded", () => {
  const s = play([toast(1, true), { type: "ToastTimeout", id: 1 }]);
  assert.equal(viewFor(s, "A").mode, "idle");
  assert.equal(viewFor(s, "A").showCriticalIndicator, true);
  assert.equal(viewFor(s, "A").toast, null);
  const hovered = reduce(s, hoverA).state;
  assert.equal(viewFor(hovered, "A").mode, "expanded");
  assert.equal(viewFor(hovered, "A").showCriticalIndicator, true);
  const cleared = reduce(hovered, { type: "ToastDismissed", id: 1 }).state;
  assert.equal(viewFor(cleared, "A").showCriticalIndicator, false);
});

test("launcher: shows on the owner only, with exclusive focus and sub", () => {
  const s = play([{ type: "LauncherToggle", monitor: "A", sub: "apps" }]);
  const a = viewFor(s, "A");
  assert.equal(a.mode, "launcher");
  assert.equal(a.sub, "apps");
  assert.equal(a.keyboardFocus, "exclusive");
  const b = viewFor(s, "B");
  assert.equal(b.mode, "idle");
  assert.equal(b.keyboardFocus, "none");
});

test("priority: launcher beats toast and expanded", () => {
  const s = play([hoverA, toast(1), { type: "LauncherToggle", monitor: "A" }]);
  assert.equal(viewFor(s, "A").mode, "launcher");
  assert.equal(viewFor(s, "A").toast, null);
});

test("priority: power replaces launcher and exposes the hold", () => {
  const s = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "PowerOpen", monitor: "A", action: "poweroff" },
    { type: "HoldStart", action: "poweroff" },
  ]);
  const view = viewFor(s, "A");
  assert.equal(view.mode, "power");
  assert.equal(view.sub, "poweroff");
  assert.deepEqual(view.hold, { action: "poweroff" });
});

test("priority: polkit beats power and returns to it when cancelled", () => {
  const power = play([{ type: "PowerOpen", monitor: "A" }]);
  const polkit = reduce(power, {
    type: "PolkitRequest",
    flowId: "f1",
    monitor: "A",
  }).state;
  const view = viewFor(polkit, "A");
  assert.equal(view.mode, "polkit");
  assert.equal(view.keyboardFocus, "exclusive");
  assert.equal(view.hold, null);
  assert.equal(viewFor(polkit, "B").mode, "idle");
  const back = reduce(polkit, { type: "PolkitCancel" }).state;
  assert.equal(viewFor(back, "A").mode, "power");
});

test("blinkDot: surfaces the global unread flag on every monitor", () => {
  const s = play([{ type: "Dnd", on: true }, toast(1)]);
  assert.equal(viewFor(s, "A").blinkDot, true);
  assert.equal(viewFor(s, "B").blinkDot, true);
});

test("unknown monitor: reads as idle without throwing", () => {
  assert.equal(viewFor(play([]), "Z").mode, "idle");
});

test("toastPaused: the single toast timer runs while nobody hovers", () => {
  assert.equal(toastPaused(play([toast(1)])), false);
});

test("toastPaused: hovering the toast on any monitor pauses it", () => {
  const onB = { type: "ToastHover", monitor: "B", on: true };
  assert.equal(toastPaused(play([toast(1), onB])), true);
  const notchB = { type: "Hover", monitor: "B", on: true };
  assert.equal(toastPaused(play([toast(1), notchB])), true);
});

test("unreadDot: hidden with nothing unread, steady once something arrived", () => {
  const hidden = { visible: false, blinking: false };
  const steady = { visible: true, blinking: false };
  assert.deepEqual(unreadDot(play([]), false), hidden);
  assert.deepEqual(unreadDot(play([]), true), steady);
  assert.deepEqual(unreadDot(play([{ type: "Dnd", on: true }]), true), steady);
  assert.deepEqual(unreadDot(play([{ type: "Dnd", on: true }]), false), hidden);
});

test("unreadDot: blinks while a keyboard state or polkit is open, steady after", () => {
  const blinking = { visible: true, blinking: true };
  const launcher = play([{ type: "LauncherToggle", monitor: "A" }]);
  assert.deepEqual(unreadDot(launcher, true), blinking);
  const power = play([{ type: "PowerOpen", monitor: "B" }]);
  assert.deepEqual(unreadDot(power, true), blinking);
  const polkit = play([{ type: "PolkitRequest", flowId: "f1", monitor: "A" }]);
  assert.deepEqual(unreadDot(polkit, true), blinking);
  assert.deepEqual(unreadDot(launcher, false), {
    visible: false,
    blinking: false,
  });
  const closed = reduce(launcher, { type: "Close", monitor: "A" }).state;
  assert.deepEqual(unreadDot(closed, true), { visible: true, blinking: false });
});

test("launcher: exposes the query and selection, empty and first by default", () => {
  const open = play([{ type: "LauncherToggle", monitor: "A" }]);
  assert.equal(viewFor(open, "A").query, "");
  assert.equal(viewFor(open, "A").index, 0);
  const typed = play([
    { type: "LauncherToggle", monitor: "A" },
    { type: "LauncherQuery", text: "fire" },
    { type: "LauncherMove", step: 1, count: 3 },
  ]);
  assert.equal(viewFor(typed, "A").query, "fire");
  assert.equal(viewFor(typed, "A").index, 1);
});
