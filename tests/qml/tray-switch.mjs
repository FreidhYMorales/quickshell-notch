import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("right-clicking Arch alternates tray and workspaces", () => {
  const result = runTrayProbe("./tray-switch.qml", { NOTCH_TEST_ICON: "1" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /tray switch: rows alternate/);
});
