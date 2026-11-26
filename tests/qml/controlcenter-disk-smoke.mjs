import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

test("smoke mode does not sample disk activity with the control center open", () => {
  const dir = mkdtempSync("/tmp/opencode/cc-disk-smoke-");
  try {
    writeFileSync(
      `${dir}/mountinfo`,
      "31 22 259:2 / / rw,relatime - ext4 /dev/nvme0n1p2 rw\n",
    );
    writeFileSync(
      `${dir}/diskstats`,
      "259 2 nvme0n1p2 100 0 10 1 20 0 20 2 0 0 0\n",
    );
    Object.assign(process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_CC_URL:
        new URL("../../shell/notches/controlcenter", import.meta.url).href,
      NOTCH_SYSINFO_MOUNTINFO: `${dir}/mountinfo`,
      NOTCH_SYSINFO_DISKSTATS: `${dir}/diskstats`,
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
    });
    const result = spawnSync("qs", [
      "-p",
      new URL("./controlcenter-disk-smoke.qml", import.meta.url).pathname,
    ], {
      encoding: "utf8",
      timeout: 8000,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
