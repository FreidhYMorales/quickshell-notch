import { test } from "node:test";
import assert from "node:assert/strict";
import { pamDir, runProbe } from "./pam-fixture.mjs";

test("a fingerprint cannot unlock during screensaver but works after wake", () => {
  const result = runProbe("lock-auth-stage", {
    NOTCH_LOCK_PAM_DIR: pamDir(["fail", "ok", "ok"]),
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock stage: fingerprint blocked/);
  assert.match(log, /lock stage: fingerprint resumed/);
});
