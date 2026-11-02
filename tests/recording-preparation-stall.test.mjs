import { test } from "node:test";
import assert from "node:assert/strict";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

// Installs `name` as a fake that stalls when its arguments match `stalls`
// (a shell case pattern) and otherwise runs the real tool.
function expectStallReported(name, stalls) {
  const dir = mkdtempSync("/tmp/opencode/notch-preparation-stall-");
  try {
    writeFileSync(
      join(dir, name),
      `#!/bin/sh
case "$*" in ${stalls}) echo $$ > "$PID_LOG"; exec sleep 30 ;; esac
exec /usr/bin/${name} "$@"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/bin/sh\ntouch "$CAPTURE_LOG"\n`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-helper-stall.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      PID_LOG: join(dir, "pid.log"),
      CAPTURE_LOG: join(dir, "capture.log"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /helper stall: reported/);
    assert.equal(existsSync(join(dir, "capture.log")), false);
    const pid = Number(readFileSync(join(dir, "pid.log"), "utf8"));
    assert.throws(() => process.kill(pid, 0), { code: "ESRCH" });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("stalled workspace creator is terminated and reported", () => {
  expectStallReported("mktemp", "-d*");
});

test("stalled video reservation is terminated and reported", () => {
  expectStallReported("mktemp", "--suffix=.mp4*");
});
