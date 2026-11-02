import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("the central notch displays the countdown while it is active", () => {
  const result = runTrayProbe("./recording-countdown-display.qml", {
    NOTCH_TEST_IDLE:
      new URL("../../shell/notches/center/CenterIdle.qml", import.meta.url)
        .href,
    NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /countdown display: 5, 1, hidden/,
  );
});
