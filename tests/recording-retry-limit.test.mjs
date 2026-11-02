import { test } from "node:test";
import assert from "node:assert/strict";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("ten sidecar collisions report failure without starting capture", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-retry-limit-");
  const recordings = join(dir, "recordings");
  try {
    mkdirSync(recordings);
    for (let i = 0; i < 10; i++) {
      writeFileSync(join(recordings, `recording-${i}.mp4.ts`), `existing ${i}`);
    }
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
path = os.path.join(os.environ['QS_RECORDINGS_DIR'], 'recording-' + str(count) + '.mp4')
with open(path, 'x'): pass
print(path)
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\n',
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "probe.qml"),
      `
import QtQuick
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    Component.onCompleted: services.recorder.start()
    Timer { interval: 5000; running: true; onTriggered: {
        if (root.services.notifs.history.length === 0) { console.error("retry limit: failure notification missing"); Qt.exit(1); }
        else { console.log("retry limit: failure reported"); Qt.exit(0); }
    } }
}`,
    );
    const capture = join(dir, "capture.log");
    const count = join(dir, "count");
    const result = runTrayProbe(join(dir, "probe.qml"), {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      RESERVE_COUNT: count,
      CAPTURE_LOG: capture,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(
      readFileSync(count, "utf8"),
      "10",
      "try exactly ten candidates",
    );
    assert.equal(existsSync(capture), false, "capture must not start");
    for (let i = 0; i < 10; i++) {
      assert.equal(
        readFileSync(join(recordings, `recording-${i}.mp4.ts`), "utf8"),
        `existing ${i}`,
      );
    }
    assert.equal(result.status, 0, result.stdout + result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
