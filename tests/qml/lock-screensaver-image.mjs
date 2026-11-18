import { test } from "node:test";
import assert from "node:assert/strict";
import { runProbe } from "./pam-fixture.mjs";

test("the lock's screensaver layer shows the chosen wallpaper, or each monitor's own", () => {
  const result = runProbe("lock-screensaver-image", {
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(
    log,
    /lock screensaver image: off \/w\/chosen\.png, on \/w\/desk\.png/,
  );
});
