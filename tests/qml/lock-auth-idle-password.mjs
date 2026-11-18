import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe, testPassword } from "./pam-fixture.mjs";

test("a correct password is refused during the screensaver", () => {
  const result = runProbe("lock-auth-idle-password", {
    NOTCH_LOCK_PAM_DIR: pamDir(),
    NOTCH_LOCK_TRY: testPassword,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock idle auth: password blocked/, log);
  assert.match(log, /lock idle auth: password resumed/, log);
});
