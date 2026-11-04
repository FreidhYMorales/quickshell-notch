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

const oldIdle =
  '{"screensaverTimeoutMin":1,"lockTimeoutMin":5,"suspendTimeoutMin":15,"screensaverUseWallpaper":true,"screensaverPath":"/w/x.png"}';

function run(stateHome) {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./idle-import.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: stateHome,
      NOTCH_SMOKE: "0",
      NOTCH_POWER_DRY_RUN: "1",
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
        .href,
    }),
  });
  return result.stdout + result.stderr;
}

test("first run imports the old idle timeouts and leaves the old file untouched", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-idle-import-"));
  try {
    mkdirSync(join(dir, "quickshell"));
    writeFileSync(join(dir, "quickshell", "idle.json"), oldIdle);
    const output = run(dir);
    assert.match(output, /idle timeouts: 1\/5\/15/, output);
    assert.deepEqual(
      JSON.parse(
        readFileSync(join(dir, "quickshell-notch", "idle.json"), "utf8"),
      ),
      { screensaverTimeoutMin: 1, lockTimeoutMin: 5, suspendTimeoutMin: 15 },
    );
    assert.equal(
      readFileSync(join(dir, "quickshell", "idle.json"), "utf8"),
      oldIdle,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("an existing notch idle state wins and nothing is imported", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-idle-import-"));
  const notchIdle =
    '{"screensaverTimeoutMin":2,"lockTimeoutMin":4,"suspendTimeoutMin":0}';
  try {
    mkdirSync(join(dir, "quickshell"));
    mkdirSync(join(dir, "quickshell-notch"));
    writeFileSync(join(dir, "quickshell", "idle.json"), oldIdle);
    writeFileSync(join(dir, "quickshell-notch", "idle.json"), notchIdle);
    const output = run(dir);
    assert.match(output, /idle timeouts: 2\/4\/0/, output);
    assert.equal(
      readFileSync(join(dir, "quickshell-notch", "idle.json"), "utf8"),
      notchIdle,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
