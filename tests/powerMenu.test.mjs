import { test } from "node:test";
import assert from "node:assert/strict";
import {
  ACTIONS,
  commandFor,
  inkCentreOffset,
  needsHold,
} from "../shell/logic/powerMenu.mjs";

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
  assert.deepEqual(commandFor("logout"), { argv: ["uwsm", "stop"] });
  assert.deepEqual(commandFor("reboot"), { argv: ["systemctl", "reboot"] });
  assert.deepEqual(commandFor("poweroff"), { argv: ["systemctl", "poweroff"] });
});

test("powerMenu: lock is a session request, unknown actions map to nothing", () => {
  assert.deepEqual(commandFor("lock"), { lock: true });
  assert.equal(commandFor("unknown"), null);
});

test("powerMenu: icons shift so their ink, not their advance, is centred", () => {
  // ⏻ at 18px in IosevkaTerm: advance 9, ink from 0 spanning 16.
  assert.equal(inkCentreOffset({ advance: 9, inkX: 0, inkWidth: 16 }), -3.5);
  // 󰤄: ink starts 1px left of the origin and spans 13.
  assert.equal(inkCentreOffset({ advance: 9, inkX: -1, inkWidth: 13 }), -1);
  // Ink that already matches the advance needs no shift.
  assert.equal(inkCentreOffset({ advance: 9, inkX: 0, inkWidth: 9 }), 0);
});
