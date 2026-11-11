import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("an in-memory frame can be moved and released without taking input", () => {
  const result = runProbe("lock-frame-view", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /frame view: captured, released and recaptured/);
});
