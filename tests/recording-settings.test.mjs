import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, extname, join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("capture uses full screen, system audio and an MP4 output", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-settings-");
  try {
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/python3
import json, os, signal, sys, time
signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
open(os.environ['CAPTURE_LOG'], 'w').write(json.dumps(sys.argv[1:]))
time.sleep(10)
`,
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-service.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: join(dir, "arguments.json"),
      QS_RECORDINGS_DIR: dir,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    const args = JSON.parse(readFileSync(join(dir, "arguments.json"), "utf8"));
    assert.equal(args.length, 8);
    assert.deepEqual(args.slice(0, 7), [
      "-w",
      "screen",
      "-a",
      "default_output",
      "-c",
      "mp4",
      "-o",
    ]);
    assert.equal(dirname(args[7]), dir);
    assert.equal(extname(args[7]), ".mp4");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
