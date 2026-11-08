import test from "node:test";
import assert from "node:assert/strict";
import { initialState, reduce } from "../shell/logic/centerState.mjs";

test("theme command opens only inside launcher and returns without closing it", () => {
  let state = initialState(["eDP-1"]);
  assert.equal(reduce(state, { type: "ThemeOpen" }).state, state);
  state = reduce(state, { type: "LauncherToggle", monitor: "eDP-1" }).state;
  state = reduce(state, { type: "ThemeOpen" }).state;
  assert.equal(state.global.keyboard.sub, "theme");
  state = reduce(state, { type: "ThemeBack" }).state;
  assert.equal(state.global.keyboard.sub, null);
  assert.equal(state.global.keyboard.kind, "launcher");
});

test("theme view closes on session lock", () => {
  let state = initialState(["eDP-1"]);
  state = reduce(state, { type: "LauncherToggle", monitor: "eDP-1" }).state;
  state = reduce(state, { type: "ThemeOpen" }).state;
  state = reduce(state, { type: "Locked", on: true }).state;
  assert.equal(state.global.keyboard, null);
});
