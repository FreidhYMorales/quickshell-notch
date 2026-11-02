import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("hovering the corner opens the tray notch", () => {
  const result = runTrayProbe("./tray-hover.qml");
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /tray hover: notch opened/);
});
