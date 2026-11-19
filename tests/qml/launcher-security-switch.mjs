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

function run(dir, click) {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./launcher-security-switch.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 30000,
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: dir,
      NOTCH_PROBE_STEP: click ? "1" : "0",
      NOTCH_SMOKE: "0",
      NOTCH_LAUNCH_DRY_RUN: "1",
      NOTCH_POWER_DRY_RUN: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  return output;
}

function notchState(dir) {
  return JSON.parse(
    readFileSync(join(dir, "quickshell-notch", "security.json"), "utf8"),
  );
}

test("turning the switch on is saved and kept after a restart", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-switch-"));
  try {
    mkdirSync(join(dir, "quickshell-notch"));
    writeFileSync(
      join(dir, "quickshell-notch", "security.json"),
      '{"fingerprintEnabled":false}',
    );
    assert.match(
      run(dir, true),
      /security switch: \[󰄲 {2}Fingerprint unlock\]/,
    );
    assert.deepEqual(notchState(dir), { fingerprintEnabled: true });
    assert.match(
      run(dir, false),
      /security switch: \[󰄲 {2}Fingerprint unlock\]/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("turning off the old shell's switch saves it in the notch state", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-switch-"));
  try {
    mkdirSync(join(dir, "quickshell"));
    writeFileSync(
      join(dir, "quickshell", "security.json"),
      '{"fingerprintEnabled":true}',
    );
    assert.match(
      run(dir, true),
      /security switch: \[󰄱 {2}Fingerprint unlock\]/,
    );
    assert.deepEqual(notchState(dir), { fingerprintEnabled: false });
    assert.deepEqual(
      JSON.parse(
        readFileSync(join(dir, "quickshell", "security.json"), "utf8"),
      ),
      { fingerprintEnabled: true },
    );
    assert.match(
      run(dir, false),
      /security switch: \[󰄱 {2}Fingerprint unlock\]/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
