import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("capture gate completes once on readiness, failure, or deadline", () => {
  const result = runProbe("lock-frame-gate", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /frame gate: all scenarios passed/);
});
