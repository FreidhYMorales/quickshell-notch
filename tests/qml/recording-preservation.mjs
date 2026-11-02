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
import { runTrayProbe } from "./run-tray.mjs";

test("a new recording preserves an existing recording", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-preserve-");
  const recordings = join(dir, "recordings");
  try {
    mkdirSync(recordings);
    writeFileSync(join(recordings, "recording-AAAAAAAA.mp4"), "original");
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    open(path, 'w').write('new recording')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    open(path + '.ts', 'w').write('123 456\\n')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(
      readFileSync(join(recordings, "recording-AAAAAAAA.mp4"), "utf8"),
      "original",
    );
    const files = readdirSync(recordings).filter((name) =>
      name !== "recording-AAAAAAAA.mp4"
    );
    assert.equal(files.length, 1);
    assert.equal(
      readFileSync(join(recordings, files[0]), "utf8"),
      "new recording",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
