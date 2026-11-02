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

test("stalled workspace cleanup still reports the saved video", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-cleanup-stall-");
  const recordings = join(dir, "recordings");
  try {
    writeFileSync(
      join(dir, "rm"),
      `#!/bin/sh\necho $$ > "$PID_LOG"\nexec sleep 30\n`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
def stop(*_):
    with open(path, 'w') as f: f.write('saved video')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
with open(path + '.ts', 'w') as f: f.write('123 456\\n')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-cleanup-stall.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: recordings,
      PID_LOG: join(dir, "pid.log"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /cleanup stall: saved reported/,
    );
    const videos = readdirSync(recordings).filter((name) =>
      name.endsWith(".mp4")
    );
    assert.equal(videos.length, 1);
    assert.equal(
      readFileSync(join(recordings, videos[0]), "utf8"),
      "saved video",
    );
    const pid = Number(readFileSync(join(dir, "pid.log"), "utf8"));
    assert.throws(() => process.kill(pid, 0), { code: "ESRCH" });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
