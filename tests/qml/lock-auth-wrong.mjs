import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe, testPassword } from "./pam-fixture.mjs";

test("a wrong password shows an error, stays locked, then the correct one unlocks", () => {
  const result = runProbe("lock-auth-wrong", {
    NOTCH_LOCK_PAM_DIR: pamDir(),
    NOTCH_LOCK_WRONG: "wrong-horse",
    NOTCH_LOCK_TRY: testPassword,
  });
  const log = result.stdout + result.stderr;
  const events = log.match(/lock: (unlocked|error .+)/g);
  assert.deepEqual(events, ["lock: error Login failed", "lock: unlocked"], log);
  assert.equal(result.status, 0, log);
});
