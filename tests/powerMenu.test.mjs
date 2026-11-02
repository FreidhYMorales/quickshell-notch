import { test } from "node:test";
import assert from "node:assert/strict";
import { ACTIONS, commandFor, needsHold } from "../shell/logic/powerMenu.mjs";

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

test("powerMenu: each action maps to its command", () => {
  assert.deepEqual(commandFor("suspend"), {
    argv: ["systemctl", "suspend-then-hibernate"],
  });
  assert.deepEqual(commandFor("logout"), {
    argv: ["hyprctl", "dispatch", "hl.dsp.exit()"],
  });
  assert.deepEqual(commandFor("reboot"), { argv: ["systemctl", "reboot"] });
  assert.deepEqual(commandFor("poweroff"), { argv: ["systemctl", "poweroff"] });
});

test("powerMenu: lock is a session request, unknown actions map to nothing", () => {
  assert.deepEqual(commandFor("lock"), { lock: true });
  assert.equal(commandFor("unknown"), null);
});
