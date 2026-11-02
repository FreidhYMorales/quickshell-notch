import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./run-tray.mjs";

test("stopping recording hides the notch indicator", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-stop-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output=$2; shift ;;
    -write-first-frame-ts) readiness=$2; shift ;;
  esac
  shift
done
if [ "$readiness" = yes ]; then printf '123 456\\n' > "$output.ts"; fi
exec sleep 10
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-stop.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_SURFACE: new URL(
        "../../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
      NOTCH_TEST_IDLE:
        new URL("../../shell/notches/center/CenterIdle.qml", import.meta.url)
          .href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /recording stop: red dot hidden/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
