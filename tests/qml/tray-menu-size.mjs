import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

function probe(count) {
  const result = runTrayProbe("./tray-menu-size.qml", {
    NOTCH_TEST_ICON: "1",
    NOTCH_TEST_MENU: "1",
    NOTCH_TEST_MENU_COUNT: String(count),
  });
  return { output: result.stdout + result.stderr, status: result.status };
}

test("a short menu grows the notch below half the screen", () => {
  const { output, status } = probe(2);
  assert.equal(status, 0, output);
  assert.match(output, /tray menu size: ok/);
});

test("a long menu stops the notch at half the screen", () => {
  const { output, status } = probe(80);
  assert.equal(status, 0, output);
  assert.match(output, /tray menu size: ok/);
});
