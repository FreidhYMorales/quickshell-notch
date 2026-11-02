import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("tray stays visible while closing before workspace reveal", () => {
  const result = runTrayProbe("./tray-close.qml", { NOTCH_TEST_ICON: "1" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /tray close: row changes after exit/,
  );
});
