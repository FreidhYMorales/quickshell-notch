import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("workspace notch shows one icon for each of two tray apps", () => {
  const result = runTrayProbe("./tray-multiple.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_COUNT: "2",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /tray multiple: two icons shown/);
});
