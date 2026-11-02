import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("tray retains priority while closing, then workspaces resume", () => {
  const result = runTrayProbe("./tray-closing-priority.qml", {
    NOTCH_TEST_ICON: "1",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /tray priority: exit preserved; next workspace shown/,
  );
});
