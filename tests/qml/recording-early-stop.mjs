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
import { runTrayProbe } from "./run-tray.mjs";

test("an early stop waits until the recorder is ready", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-early-stop-");
  const recordings = join(dir, "recordings");
  const events = join(dir, "events.log");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
events = os.environ['EVENT_LOG']
output = sys.argv[sys.argv.index('-o') + 1]
ready = False
def log(message):
    with open(events, 'a') as f: f.write(message + '\\n')
def stop(*_):
    if not ready:
        log('stop-before-ready')
        sys.exit(3)
    log('stopped')
    with open(output, 'w') as f: f.write('saved video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
log('started')
time.sleep(2)
if '-write-first-frame-ts' in sys.argv and sys.argv[sys.argv.index('-write-first-frame-ts') + 1] == 'yes':
    with open(output + '.ts', 'w') as f: f.write('123 456\\n')
    ready = True
    log('ready')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-early-stop.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      EVENT_LOG: events,
      QS_RECORDINGS_DIR: recordings,
      NOTCH_TEST_SURFACE: new URL(
        "../../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
    });
    assert.equal(readFileSync(events, "utf8"), "started\nready\nstopped\n");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /early stop: saved after readiness/,
    );
    const videos = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4")
    );
    assert.equal(videos.length, 1);
    assert.equal(
      readFileSync(join(recordings, videos[0]), "utf8"),
      "saved video",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
