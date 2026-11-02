import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("choosing an enabled option sends the action to the app", () => {
  const result = runTrayProbe("./tray-menu-activate.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: action sent/);
  assert.match(output, /FAKE_MENU_EVENT 1 clicked/);
});
