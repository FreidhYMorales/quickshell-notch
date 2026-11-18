import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the screensaver layer contracts when the stage returns to normal", () => {
  const result = runProbe("lock-manual-overlay", {
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /lock manual layer: contracted into the notch/);
});
