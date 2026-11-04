import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe } from "./pam-fixture.mjs";

test("a recognised fingerprint unlocks the session", () => {
  const result = runProbe("lock-auth-fingerprint", {
    NOTCH_LOCK_PAM_DIR: pamDir(["ok"]),
  });
  const log = result.stdout + result.stderr;
  assert.match(log, /lock: unlocked/, log);
  assert.equal(result.status, 0, log);
});
