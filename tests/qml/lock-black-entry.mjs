import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the black frame expands before outputs turn off", () => {
  const result = runProbe("lock-black-entry", {
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock black: expanded before outputs off/);
});
