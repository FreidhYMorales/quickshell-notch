import { test } from "node:test";
import assert from "node:assert/strict";
import { ACTIONS, needsHold } from "../shell/logic/powerMenu.mjs";

test("powerMenu: actions in display order", () => {
  assert.deepEqual(ACTIONS, [
    "lock",
    "suspend",
    "logout",
    "reboot",
    "poweroff",
  ]);
});

test("powerMenu: only session-ending actions need a hold", () => {
  assert.equal(needsHold("lock"), false);
  assert.equal(needsHold("suspend"), false);
  assert.equal(needsHold("logout"), true);
  assert.equal(needsHold("reboot"), true);
  assert.equal(needsHold("poweroff"), true);
  assert.equal(needsHold("unknown"), false);
});
