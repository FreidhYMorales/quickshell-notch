import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe, testPassword } from "./pam-fixture.mjs";

test("the lock screen shows a wrong password error, empties the field, then unlocks", () => {
  const result = runProbe("lock-content-wrong", {
    NOTCH_LOCK_PAM_DIR: pamDir(),
    NOTCH_LOCK_WRONG: "wrong-horse",
    NOTCH_LOCK_TRY: testPassword,
  });
  const log = result.stdout + result.stderr;
  const events = log.match(/lock content: .+/g);
  assert.deepEqual(events, [
    "lock content: shown Login failed, field empty",
    "lock content: unlocked",
  ], log);
  assert.equal(result.status, 0, log);
});
