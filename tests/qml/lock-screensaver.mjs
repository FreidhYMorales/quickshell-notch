import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the screensaver and black stages hide the lock content until an input", () => {
  const result = runProbe("lock-screensaver", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock screensaver: hidden, woke, form shown/);
});
