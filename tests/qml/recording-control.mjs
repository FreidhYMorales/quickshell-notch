import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("the idle control center shows a recording control", () => {
  const result = runTrayProbe("./recording-control.qml", {
    NOTCH_TEST_SURFACE: new URL(
      "../../shell/notches/controlcenter/ControlCenterSurface.qml",
      import.meta.url,
    ).href,
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /recording control: visible/);
});
