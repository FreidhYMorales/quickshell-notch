import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("left-clicking a tray icon activates its app", () => {
  const result = runTrayProbe("./tray-activate.qml", { NOTCH_TEST_ICON: "1" });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /tray activation: click sent/);
  assert.match(output, /FAKE_ACTIVATED/);
});
