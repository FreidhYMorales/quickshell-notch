import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the session keeps the idle stage and only darkens an already locked session", () => {
  const result = runProbe("lock-stage", {
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(
    log,
    /lock stage: screensaver, normal, black, normal/,
  );
});
