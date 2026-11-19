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

// fprintd-list with no finger registered.
const fakeList = `#!/bin/sh
printf '%s\\n' 'Using device /net/reactivated/Fprint/Device/0' 'User me has no fingerprints enrolled for Fake Sensor.'
`;

// fprintd-enroll that records its arguments, reports one passed touch and
// keeps waiting for the next one.
function fakeEnroll(dir) {
  return `#!/bin/sh
printf '%s\\n' "$*" > '${join(dir, "enroll-args")}'
printf '%s\\n' 'Using device /net/reactivated/Fprint/Device/0' 'Enrolling left-thumb finger.' 'Enroll result: enroll-stage-passed'
sleep 10
`;
}

test("picking a free finger shows its enrollment progress and hint", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-enroll-"));
  try {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "fprintd-list"), fakeList, { mode: 0o755 });
    writeFileSync(join(bin, "fprintd-enroll"), fakeEnroll(dir), {
      mode: 0o755,
    });
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-security-enroll.qml", import.meta.url),
      ),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        PATH: `${bin}:${process.env.PATH}`,
        USER: "me",
        XDG_STATE_HOME: dir,
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
    assert.match(
      output,
      /security enroll: \[Enrolling Left thumb \| Touch the sensor again \| Touches: 1\]/,
    );
    assert.equal(
      readFileSync(join(dir, "enroll-args"), "utf8"),
      "-f left-thumb me\n",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
