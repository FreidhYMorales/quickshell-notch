import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe } from "./pam-fixture.mjs";

test("a failed fingerprint shows an error, listens again, and the next scan unlocks", () => {
  const result = runProbe("lock-auth-fingerprint-retry", {
    NOTCH_LOCK_PAM_DIR: pamDir(["fail", "ok"]),
  });
  const log = result.stdout + result.stderr;
  const events = log.match(/lock: (unlocked|fingerprint \w+)/g);
  assert.deepEqual(events, [
    "lock: fingerprint error",
    "lock: fingerprint listening",
    "lock: unlocked",
  ], log);
  assert.equal(result.status, 0, log);
});
