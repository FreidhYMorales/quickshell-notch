import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("a memory-only screen capture becomes ready and stays available", () => {
  const result = runProbe("screencopy-probe", {});
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /screencopy probe: ready \d+ms \d+x\d+/);
  assert.match(log, /screencopy probe: retained/);
});
