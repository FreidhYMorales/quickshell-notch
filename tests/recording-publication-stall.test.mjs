import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("stalled publication is terminated and reports the video location", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-publish-stall-");
  const recordings = join(dir, "recordings");
  try {
    writeFileSync(
      join(dir, "ln"),
      `#!/bin/sh
case "$2" in *.ts) exec /usr/bin/ln "$@" ;; esac
echo $$ > "$PID_LOG"
exec sleep 30
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('recoverable video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
with open(path + '.ts', 'w') as f: f.write('123 456\\n')
with open(os.environ['CAPTURE_LOG'], 'w') as f: f.write(path)
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const log = join(dir, "capture.log");
    const result = runTrayProbe("./recording-publication-stall.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      CAPTURE_LOG: log,
      PID_LOG: join(dir, "pid.log"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /publication stall: location reported/,
    );
    const capture = readFileSync(log, "utf8");
    assert.equal(readFileSync(capture, "utf8"), "recoverable video");
    assert.equal(
      readdirSync(recordings).filter((name) => name.endsWith(".mp4")).length,
      0,
    );
    const pid = Number(readFileSync(join(dir, "pid.log"), "utf8"));
    assert.throws(() => process.kill(pid, 0), { code: "ESRCH" });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
