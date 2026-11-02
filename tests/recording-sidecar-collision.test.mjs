import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("an existing readiness sidecar is preserved", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-sidecar-collision-");
  const recordings = join(dir, "recordings");
  try {
    mkdirSync(recordings);
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
path = os.path.join(os.path.dirname(sys.argv[-1]), name)
with open(path, 'x'): pass
if count == 0:
    with open(path + '.ts', 'x') as f: f.write('existing sidecar')
    with open(os.environ['CONFLICT_LOG'], 'w') as f: f.write(path)
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
      CONFLICT_LOG: join(dir, "conflict.log"),
      CAPTURE_LOG: join(dir, "capture.log"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    const conflict = readFileSync(join(dir, "conflict.log"), "utf8");
    assert.equal(readFileSync(`${conflict}.ts`, "utf8"), "existing sidecar");
    const selected = readFileSync(join(dir, "capture.log"), "utf8");
    assert.notEqual(
      selected,
      conflict,
      "capture must not use a path with an existing sidecar",
    );
    const published = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4")
    );
    assert.equal(published.length, 1);
    assert.equal(
      readFileSync(join(recordings, published[0]), "utf8"),
      "saved recording",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
