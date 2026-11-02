import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("valid and missing pixmaps render their expected provider images", () => {
  const valid = runTrayProbe("./tray-image-ready.qml", {
    NOTCH_TEST_ICON: "1",
  });
  const missing = runTrayProbe("./tray-image-ready.qml");
  const validOutput = valid.stdout + valid.stderr;
  const missingOutput = missing.stdout + missing.stderr;
  assert.equal(valid.status, 0, validOutput);
  assert.match(validOutput, /tray image: expected pixmap ready/);
  assert.doesNotMatch(validOutput, /Unable to create pixmap for tray icon/);
  assert.equal(missing.status, 0, missingOutput);
  assert.match(missingOutput, /tray image: expected pixmap ready/);
  assert.match(missingOutput, /Unable to create pixmap for tray icon/);
});
