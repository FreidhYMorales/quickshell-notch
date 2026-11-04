import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe, testPassword } from "./pam-fixture.mjs";

test("the correct password unlocks the session", () => {
  const result = runProbe("lock-auth-password", {
    NOTCH_LOCK_PAM_DIR: pamDir(),
    NOTCH_LOCK_TRY: testPassword,
  });
  const log = result.stdout + result.stderr;
  assert.match(log, /lock: unlocked/, log);
  assert.equal(result.status, 0, log);
});
