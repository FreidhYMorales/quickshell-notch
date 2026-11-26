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

// fprintd-delete that records its arguments and drops the finger (-f <finger>).
function fakeDelete(dir) {
  const file = join(dir, "enrolled");
  return `#!/bin/sh
printf '%s\\n' "$*" > '${join(dir, "delete-args")}'
grep -vx "$3" '${file}' > '${file}.next'
mv '${file}.next' '${file}'
`;
}

test("removing a finger drops it from the list and keeps the others", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-security-remove-"));
  try {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(dir, "enrolled"), "left-thumb\nright-index-finger\n");
    writeFileSync(join(bin, "fprintd-list"), fakeList(dir), { mode: 0o755 });
    writeFileSync(join(bin, "fprintd-delete"), fakeDelete(dir), {
      mode: 0o755,
    });
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(
        new URL("./launcher-security-remove.qml", import.meta.url),
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
      /security remove: left-thumb=true, right-index=false/,
    );
    assert.equal(
      readFileSync(join(dir, "delete-args"), "utf8"),
      "me -f right-index-finger\n",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
