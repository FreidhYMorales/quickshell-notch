import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("recording control shows a stop icon while recording", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-stop-icon-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\nexec sleep 10\n',
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-stop-icon.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "capture.log"),
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
    });
    assert.equal(readFileSync(join(dir, "capture.log"), "utf8"), "started");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /recording icon: stop visible/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
