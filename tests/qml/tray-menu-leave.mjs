import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("closing the notch also closes the tray menu", () => {
  const result = runTrayProbe("./tray-menu-leave.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: leaving closes menu/);
});
