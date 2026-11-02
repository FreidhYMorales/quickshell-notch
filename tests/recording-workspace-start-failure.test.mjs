import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("recording reports workspace creation failure without capture", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-workspace-start-");
  try {
    writeFileSync(
      join(dir, "mktemp"),
      `#!/bin/sh
if [ "$1" = '-d' ]; then exit 1; fi
exec /usr/bin/mktemp "$@"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\n',
      { mode: 0o755 },
    );
    const capture = join(dir, "capture.log");
    const result = runTrayProbe("./recording-workspace-start-failure.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      CAPTURE_LOG: capture,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(existsSync(capture), false, "capture must not start");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /workspace start failure: reported/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
