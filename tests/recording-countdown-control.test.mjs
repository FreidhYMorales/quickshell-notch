import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("record button counts down before starting capture", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-countdown-control-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, sys, time
if '-write-first-frame-ts' in sys.argv:
    open(sys.argv[sys.argv.index('-o') + 1] + '.ts', 'w').write('123 456\\n')
open(os.environ['CAPTURE_LOG'], 'w').write(str(int(time.time() * 1000)))
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-countdown-control.qml", {
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
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    const click = /countdown UI click: (\d+)/.exec(output);
    assert.ok(click, output);
    const started = Number(readFileSync(join(dir, "capture.log"), "utf8"));
    assert.ok(
      started - Number(click[1]) >= 5000,
      "capture started before five seconds",
    );
    assert.match(output, /countdown UI: capture started/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
