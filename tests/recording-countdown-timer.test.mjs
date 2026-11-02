import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("countdown advances before recording starts", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-countdown-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\nexec sleep 10\n',
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-countdown-timer.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "capture.log"),
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_IDLE:
        new URL("../shell/notches/center/CenterIdle.qml", import.meta.url).href,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(readFileSync(join(dir, "capture.log"), "utf8"), "started");
    assert.match(
      result.stdout + result.stderr,
      /countdown timer: completed before capture/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
