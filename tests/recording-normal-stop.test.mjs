import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("a successful requested stop does not show a failure", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-normal-stop-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
def stop(*_):
    open(os.environ['CAPTURE_LOG'], 'w').write('finalized')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    open(sys.argv[sys.argv.index('-o') + 1] + '.ts', 'w').write('123 456\\n')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-normal-stop.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "capture.log"),
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
      NOTCH_TEST_IDLE:
        new URL("../shell/notches/center/CenterIdle.qml", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(readFileSync(join(dir, "capture.log"), "utf8"), "finalized");
    assert.match(
      result.stdout + result.stderr,
      /normal stop: no failure notification/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
