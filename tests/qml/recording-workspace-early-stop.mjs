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

test("stop while workspace is being prepared waits and saves", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-prepare-stop-");
  const recordings = join(dir, "recordings");
  try {
    writeFileSync(
      join(dir, "mktemp"),
      `#!/bin/sh
if [ "$1" = '-d' ]; then sleep 1; fi
exec /usr/bin/mktemp "$@"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('saved after preparation')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
with open(path + '.ts', 'w') as f: f.write('123 456\\n')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-workspace-early-stop.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /preparation stop: saved/);
    const videos = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4")
    );
    assert.equal(videos.length, 1);
    assert.equal(
      readFileSync(join(recordings, videos[0]), "utf8"),
      "saved after preparation",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
