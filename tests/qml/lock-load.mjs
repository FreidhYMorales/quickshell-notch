import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the lock loads with one idle capture host per screen", () => {
  const result = runProbe("lock-load", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock load: \d+ idle capture host\(s\)/);
});
