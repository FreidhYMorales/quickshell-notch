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

test("publication keeps an existing recording and uses a dated unique name", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-publish-collision-");
  const recordings = join(dir, "recordings");
  try {
    // The first publication target is taken just before the link is made.
    writeFileSync(
      join(dir, "ln"),
      `#!/bin/sh
case "$2" in *.ts) exec /usr/bin/ln "$@" ;; esac
if [ ! -e "$TAKEN_LOG" ]; then
  printf original > "$3"
  printf '%s' "$3" > "$TAKEN_LOG"
fi
exec /usr/bin/ln "$@"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('new video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
with open(path + '.ts', 'w') as f: f.write('123 456\\n')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const taken = join(dir, "taken.log");
    const result = runTrayProbe("./recording-publication-collision.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      TAKEN_LOG: taken,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /publication collision: saved reported/,
    );
    const first = readFileSync(taken, "utf8");
    assert.equal(readFileSync(first, "utf8"), "original");
    const videos = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4") && join(recordings, name) !== first
    );
    assert.equal(videos.length, 1, JSON.stringify(videos));
    assert.match(
      videos[0],
      /^recording-\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}-.+-2\.mp4$/,
    );
    assert.equal(
      readFileSync(join(recordings, videos[0]), "utf8"),
      "new video",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
