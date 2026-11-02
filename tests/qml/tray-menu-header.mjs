import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("separator stays between the icons and the scrolling menu", () => {
  const result = runTrayProbe("./tray-menu-header.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_COUNT: "30",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: header separator stays fixed/);
});
