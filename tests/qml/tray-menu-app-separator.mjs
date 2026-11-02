import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("app-provided separator appears between menu options", () => {
  const result = runTrayProbe("./tray-menu-app-separator.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_TYPES: "1",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray menu: app separator between options/);
});
