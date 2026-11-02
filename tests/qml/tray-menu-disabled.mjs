import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("a disabled option looks different and sends nothing", () => {
  const result = runTrayProbe("./tray-menu-disabled.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_DISABLED: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: disabled clicked/);
  assert.doesNotMatch(output, /FAKE_MENU_EVENT 2 clicked/);
});
