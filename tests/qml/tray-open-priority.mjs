import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("workspace activity does not replace the open tray", () => {
  const result = runTrayProbe("./tray-open-priority.qml", {
    NOTCH_TEST_ICON: "1",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /tray priority: open tray preserved/,
  );
});
