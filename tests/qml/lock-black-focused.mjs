import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the first key wakes black after the password field had focus", () => {
  const result = runProbe("lock-black-focused", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock black: focused password wakes on first key/);
});
