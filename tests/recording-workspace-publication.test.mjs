import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("recording captures privately and publishes the finished video", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-workspace-publish-");
  const recordings = join(dir, "recordings");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('saved video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    with open(path + '.ts', 'w') as f: f.write('123 456\\n')
with open(os.environ['CAPTURE_LOG'], 'w') as f: f.write(path)
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const log = join(dir, "capture.log");
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      CAPTURE_LOG: log,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    const temporary = readFileSync(log, "utf8");
    assert.notEqual(
      dirname(temporary),
      recordings,
      "capture must use a private workspace",
    );
    assert.equal(dirname(dirname(temporary)), recordings);
    const published = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4")
    );
    assert.equal(published.length, 1);
    assert.equal(
      readFileSync(join(recordings, published[0]), "utf8"),
      "saved video",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
