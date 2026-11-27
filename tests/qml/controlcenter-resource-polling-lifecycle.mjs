import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

test("resource polling follows the open monitors until the last closes", () => {
  const dir = mkdtempSync("/tmp/opencode/cc-resource-lifecycle-");
  try {
    writeFileSync(`${dir}/stat`, "cpu 100 0 0 100 0 0 0 0 0 0\n");
    const result = spawnSync("qs", [
      "-p",
      new URL("./controlcenter-resource-polling-lifecycle.qml", import.meta.url)
        .pathname,
    ], {
      encoding: "utf8",
      timeout: 22000,
      env: Object.assign({}, process.env, {
        NOTCH_CC_URL:
          new URL("../../shell/notches/controlcenter", import.meta.url).href,
        NOTCH_SMOKE: "0",
        NOTCH_SYSINFO_STAT: `${dir}/stat`,
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
