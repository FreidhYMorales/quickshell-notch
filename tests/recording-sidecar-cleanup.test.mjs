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

for (const replaced of [false, true]) {
  test(
    replaced
      ? "cleanup preserves a replaced sidecar"
      : "cleanup removes the owned sidecar",
    () => {
      const dir = mkdtempSync("/tmp/opencode/notch-sidecar-cleanup-");
      try {
        writeFileSync(
          join(dir, "gpu-screen-recorder"),
          `#!/usr/bin/python3
import os, signal, sys, time
path = sys.argv[sys.argv.index('-o') + 1]
with open(os.environ['PATH_LOG'], 'w') as f: f.write(path)
def stop(*_):
    with open(path, 'w') as f: f.write('recording')
    if os.environ['REPLACE'] == 'yes':
        replacement = path + '.replacement'
        with open(replacement, 'w') as f: f.write('someone else')
        os.replace(replacement, path + '.ts')
    sys.exit(0)
signal.signal(signal.SIGINT, stop)
if '-write-first-frame-ts' in sys.argv:
    with open(path + '.ts', 'w') as f: f.write('123 456\\n')
time.sleep(10)
`,
          { mode: 0o755 },
        );
        const log = join(dir, "path.log");
        const result = runTrayProbe("./recording-service.qml", {
          PATH: `${dir}:${process.env.PATH}`,
          QS_RECORDINGS_DIR: join(dir, "recordings"),
          PATH_LOG: log,
          REPLACE: replaced ? "yes" : "no",
          NOTCH_SERVICES_URL:
            new URL("../shell/services", import.meta.url).href,
        });
        assert.equal(result.status, 0, result.stdout + result.stderr);
        const sidecar = readFileSync(log, "utf8") + ".ts";
        if (replaced) {
          assert.equal(readFileSync(sidecar, "utf8"), "someone else");
        } else {assert.equal(
            existsSync(sidecar),
            false,
            "owned sidecar should be removed",
          );}
      } finally {
        rmSync(dir, { recursive: true, force: true });
      }
    },
  );
}
