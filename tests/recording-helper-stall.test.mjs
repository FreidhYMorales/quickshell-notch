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

test("stalled directory creator is terminated and reported", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-helper-stall-");
  try {
    writeFileSync(
      join(dir, "mkdir"),
      `#!/bin/sh\necho $$ > "$PID_LOG"\nexec sleep 30\n`,
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
});
