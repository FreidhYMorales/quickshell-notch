import { test } from "node:test";
import assert from "node:assert/strict";
import { transition } from "../shell/logic/greetdPreview.mjs";

test("the mock authenticates before the exit animation and simulated launch", () => {
  assert.equal(transition("form", "submit"), "authenticating");
  assert.equal(transition("authenticating", "success"), "animating");
  assert.equal(transition("animating", "finished"), "launched");
  assert.equal(transition("launched", "reset"), "form");
});

test("failure returns to the form without launching or accepting duplicate input", () => {
  assert.equal(transition("authenticating", "failure"), "rejecting");
  assert.equal(transition("rejecting", "finished"), "shaking");
  assert.equal(transition("shaking", "finished"), "error");
  assert.equal(transition("error", "edit"), "form");
  assert.equal(transition("authenticating", "submit"), "authenticating");
  assert.equal(transition("authenticating", "finished"), "authenticating");
  assert.equal(transition("form", "success"), "form");
});
