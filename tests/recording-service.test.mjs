import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("recorder starts and stops a capture process", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-recorder-"));
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import os, signal, time
signal.signal(signal.SIGINT, lambda *_: (open(os.environ['CAPTURE_LOG'], 'a').write('stopped'), exit(0)))
open(os.environ['CAPTURE_LOG'], 'w').write('started,')
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "capture.log"),
      QS_RECORDINGS_DIR: dir,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.equal(
      readFileSync(join(dir, "capture.log"), "utf8"),
      "started,stopped",
    );
    assert.match(output, /recording service: started and stopped/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
