import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("workspace notch shows a generic symbol for a missing named icon", () => {
  const result = runTrayProbe("./tray-generic.qml", {
    NOTCH_TEST_ICON: "missing",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /tray generic: fallback shown/);
});
