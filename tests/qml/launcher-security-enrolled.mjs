import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// fprintd-list printing the fingers stored in the runner's "enrolled" file.
function fakeList(dir) {
  return `#!/bin/sh
printf '%s\\n' 'Using device /net/reactivated/Fprint/Device/0' 'Fingerprints for user me on Fake Sensor (press):'
n=0
while read -r finger; do printf ' - #%s: %s\\n' "$n" "$finger"; n=$((n + 1)); done < '${
    join(dir, "enrolled")
  }'
`;
}

// fprintd-enroll that takes one touch and then stores the finger (-f <finger>).
function fakeEnroll(dir) {
  return `#!/bin/sh
printf '%s\\n' 'Enroll result: enroll-stage-passed'
sleep 0.5
printf '%s\\n' "$2" >> '${join(dir, "enrolled")}'
printf '%s\\n' 'Enroll result: enroll-completed'
`;
}

test("a completed enrollment lists the new finger and closes the panel", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-enrolled-"));
  try {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(dir, "enrolled"), "right-index-finger\n");
    writeFileSync(join(bin, "fprintd-list"), fakeList(dir), { mode: 0o755 });
    writeFileSync(join(bin, "fprintd-enroll"), fakeEnroll(dir), {
      mode: 0o755,
    });
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-security-enrolled.qml", import.meta.url),
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
      /security enrolled: \[Left thumb, Right index\], panel hidden/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
