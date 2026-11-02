import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("simulated tray item advertises a menu", () => {
  const result = runTrayProbe("./tray-menu-fixture.qml", {
    NOTCH_TEST_MENU: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /menu fixture: menu advertised/);
});
