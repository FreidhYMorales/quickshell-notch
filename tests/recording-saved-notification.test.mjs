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

test("successful recording save shows a notification", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-saved-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    open(path, 'w').write('saved video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    open(path + '.ts', 'w').write('123 456\\n')
time.sleep(15)
`,
      { mode: 0o755 },
    );
    const recordings = join(dir, "recordings");
    const result = runTrayProbe("./recording-saved-notification.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
      NOTCH_TEST_IDLE:
        new URL("../shell/notches/center/CenterIdle.qml", import.meta.url).href,
    });
    const files = readdirSync(recordings);
    assert.equal(files.length, 1);
    assert.equal(
      readFileSync(join(recordings, files[0]), "utf8"),
      "saved video",
    );
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /recording saved: notification visible/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
