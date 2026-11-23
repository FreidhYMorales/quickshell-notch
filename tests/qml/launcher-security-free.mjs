import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// A fake fprintd-list that prints the given fingers as fprintd does.
function fakeList(fingers) {
  const lines = fingers.map((name, i) => ` - #${i}: ${name}`).join("\n");
  return `#!/bin/sh
printf '%s\\n' 'found 1 devices' 'Device at /net/reactivated/Fprint/Device/0' 'Using device /net/reactivated/Fprint/Device/0' 'Fingerprints for user me on Fake Sensor (press):'
printf '%s\\n' '${lines}'
`;
}

function run(fingers) {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-free-"));
  try {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "fprintd-list"), fakeList(fingers), {
      mode: 0o755,
    });
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-security-free.qml", import.meta.url),
      ),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        PATH: `${bin}:${process.env.PATH}`,
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
    return output;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("the security view offers every finger while none is registered", () => {
  assert.match(run([]), /security free: \[left-thumb, right-index-finger\]/);
});

test("the security view does not offer a registered finger", () => {
  assert.match(run(["right-index-finger"]), /security free: \[left-thumb\]/);
});
