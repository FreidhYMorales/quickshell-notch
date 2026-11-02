import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("simulated tray menu exposes an Open option", () => {
  const result = runTrayProbe("./tray-menu-entry.qml", {
    NOTCH_TEST_MENU: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /menu fixture: Open option available/);
});
