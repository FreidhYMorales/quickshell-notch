import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("a submenu replaces the options and a back control restores them", () => {
  const result = runTrayProbe("./tray-menu-submenu.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_SUBMENU: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: submenu replaced and back restored/);
  assert.doesNotMatch(output, /FAKE_MENU_EVENT 20 clicked/);
});
