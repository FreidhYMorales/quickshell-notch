import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("tray icon has the same displayed height as Arch", () => {
  const result = runTrayProbe("./tray-icon-size.qml", { NOTCH_TEST_ICON: "1" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /tray size: icon matches Arch/);
});
