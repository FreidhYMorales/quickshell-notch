import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./run-tray.mjs";

test("cancelling the countdown prevents capture and output", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-cancel-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\n',
      { mode: 0o755 },
    );
    const recordings = join(dir, "recordings");
    const result = runTrayProbe("./recording-countdown-cancel.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "capture.log"),
      QS_RECORDINGS_DIR: recordings,
      NOTCH_TEST_IDLE:
        new URL("../../shell/notches/center/CenterIdle.qml", import.meta.url)
          .href,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /countdown cancel: no capture/);
    assert.equal(existsSync(join(dir, "capture.log")), false);
    assert.equal(existsSync(recordings), false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
