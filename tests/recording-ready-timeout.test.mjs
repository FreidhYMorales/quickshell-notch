import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("recorder that never becomes ready is terminated and reported", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-ready-timeout-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
signal.signal(signal.SIGTERM, signal.SIG_IGN)
with open(path, 'w') as f: f.write('partial video')
with open(os.environ['CAPTURE_LOG'], 'w') as f: f.write(path)
with open(os.environ['PID_LOG'], 'w') as f: f.write(str(os.getpid()))
time.sleep(40)
`,
      { mode: 0o755 },
    );
    const log = join(dir, "capture.log");
    const result = spawnSync("dbus-run-session", [
      `--config-file=${
        fileURLToPath(new URL("./qml/test-bus.conf", import.meta.url))
      }`,
      "--",
      "qs",
      "-p",
      fileURLToPath(
        new URL("./qml/recording-ready-timeout.qml", import.meta.url),
      ),
    ], {
      encoding: "utf8",
      timeout: 23000,
      env: Object.assign({}, process.env, {
        PATH: `${dir}:${process.env.PATH}`,
        QS_RECORDINGS_DIR: join(dir, "recordings"),
        CAPTURE_LOG: log,
        PID_LOG: join(dir, "pid.log"),
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /ready timeout: stopped and reported/,
    );
    const pid = Number(readFileSync(join(dir, "pid.log"), "utf8"));
    assert.throws(() => process.kill(pid, 0), { code: "ESRCH" });
    assert.equal(
      readFileSync(readFileSync(log, "utf8"), "utf8"),
      "partial video",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
