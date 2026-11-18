import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

function run(stateHome, step) {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./launcher-screensaver-step.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 30000,
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: stateHome,
      NOTCH_PROBE_STEP: step ? "1" : "0",
      NOTCH_SMOKE: "0",
      NOTCH_LAUNCH_DRY_RUN: "1",
      NOTCH_POWER_DRY_RUN: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  return output;
}

test("a changed time updates the delays and is read back after a restart", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-screensaver-step-"));
  const file = join(dir, "quickshell-notch", "idle.json");
  try {
    mkdirSync(join(dir, "quickshell-notch"));
    writeFileSync(
      file,
      '{"screensaverTimeoutMin":2,"lockTimeoutMin":4,"suspendTimeoutMin":0}',
    );
    assert.match(run(dir, true), /screensaver step: shows 3 min, delay 180/);
    assert.equal(
      JSON.parse(readFileSync(file, "utf8")).screensaverTimeoutMin,
      3,
    );
    assert.match(run(dir, false), /screensaver step: shows 3 min, delay 180/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
