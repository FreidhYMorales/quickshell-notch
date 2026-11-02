import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("a recording that ends without a stop request reports failure", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-unexpected-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      "#!/bin/sh\nsleep 1\nexit 0\n",
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-unexpected.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
      NOTCH_TEST_IDLE:
        new URL("../shell/notches/center/CenterIdle.qml", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /unexpected exit: notified and dot hidden/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
