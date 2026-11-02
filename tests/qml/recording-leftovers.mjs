import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./run-tray.mjs";

// Runs the probe and returns the notifications posted during startup.
function startupNotices(dir, extraEnv = {}) {
  const result = runTrayProbe(
    "./recording-leftovers.qml",
    Object.assign({
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    }, extraEnv),
  );
  assert.equal(result.status, 0, result.stdout + result.stderr);
  const line = (result.stdout + result.stderr).match(/leftovers: (.*)/);
  assert.ok(line, result.stdout + result.stderr);
  return JSON.parse(line[1]);
}

test("an interrupted recording is reported at startup", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-leftovers-");
  const recordings = join(dir, "recordings");
  try {
    const workspace = join(recordings, ".notch-recording-abcd1234");
    mkdirSync(workspace, { recursive: true });
    writeFileSync(join(workspace, "recording-x.mp4"), "partial video");
    const notices = startupNotices(dir);
    assert.equal(notices.length, 1, JSON.stringify(notices));
    assert.match(notices[0], /Interrupted recording/);
    assert.ok(notices[0].includes(recordings), notices[0]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("published videos and empty placeholders are not reported", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-leftovers-");
  const recordings = join(dir, "recordings");
  try {
    const workspace = join(recordings, ".notch-recording-empty123");
    mkdirSync(workspace, { recursive: true });
    writeFileSync(join(workspace, "recording-x.mp4"), "");
    writeFileSync(join(recordings, "recording-done-1.mp4"), "saved video");
    assert.deepEqual(startupNotices(dir), []);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("the current recording's workspace is not reported", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-leftovers-");
  try {
    // Delay only the startup scan so it finishes after capture has begun.
    writeFileSync(
      join(dir, "sh"),
      `#!/usr/bin/sh
case "$2" in *notch-recording-*) sleep 1.5 ;; esac
exec /usr/bin/sh "$@"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      `#!/usr/bin/sh
path=""
while [ "$#" -gt 0 ]; do [ "$1" = -o ] && path="$2"; shift; done
printf 'live video' > "$path"
printf '123 456\\n' > "$path.ts"
exec sleep 5
`,
      { mode: 0o755 },
    );
    assert.deepEqual(startupNotices(dir, { LEFTOVER_START: "1" }), []);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
