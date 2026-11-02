import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("an existing readiness sidecar is preserved", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-sidecar-collision-");
  const recordings = join(dir, "recordings");
  const conflict = join(recordings, "recording-CONFLICT.mp4");
  const sentinel = `${conflict}.ts`;
  try {
    mkdirSync(recordings);
    writeFileSync(sentinel, "existing sidecar");
    writeFileSync(
      join(dir, "mktemp"),
      `#!/usr/bin/python3
import os, sys
if '--suffix=.mp4' not in sys.argv:
    os.execv('/usr/bin/mktemp', sys.argv)
counter = os.environ['RESERVE_COUNT']
try:
    with open(counter) as f: count = int(f.read())
except FileNotFoundError:
    count = 0
with open(counter, 'w') as f: f.write(str(count + 1))
name = 'recording-CONFLICT.mp4' if count == 0 else 'recording-SAFE' + str(count) + '.mp4'
path = os.path.join(os.environ['QS_RECORDINGS_DIR'], name)
with open(path, 'x'): pass
print(path)
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('saved recording')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    with open(path + '.ts', 'w') as f: f.write('123 456\\n')
with open(os.environ['CAPTURE_LOG'], 'w') as f: f.write(path)
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      RESERVE_COUNT: join(dir, "reserve-count"),
      CAPTURE_LOG: join(dir, "capture.log"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(readFileSync(sentinel, "utf8"), "existing sidecar");
    const selected = readFileSync(join(dir, "capture.log"), "utf8");
    assert.notEqual(
      selected,
      conflict,
      "capture must not use a path with an existing sidecar",
    );
    assert.equal(readFileSync(selected, "utf8"), "saved recording");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
