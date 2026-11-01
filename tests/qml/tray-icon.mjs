import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("workspace notch shows an available tray icon", () => {
  const result = runTrayProbe("./tray-icon.qml", { NOTCH_TEST_ICON: "1" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /tray icon: simulated icon is shown/,
  );
});
