import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("a detectable tray image error shows a generic symbol", () => {
  const result = runTrayProbe("./tray-image-error.qml", {
    NOTCH_TEST_ICON: "1",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /tray image error: generic symbol shown/,
  );
});
