import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("separators and checked options render in the menu", () => {
  const result = runTrayProbe("./tray-menu-separator.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_TYPES: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: separator and check shown/);
});
