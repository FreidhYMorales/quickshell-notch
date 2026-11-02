import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

// Runs the probe and returns the notifications posted during startup.
function startupNotices(dir, extraEnv = {}) {
  const result = runTrayProbe(
    "./recording-leftovers.qml",
    Object.assign({
      PATH: `${dir}:${process.env.PATH}`,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
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
