import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

test("network activity samples while the control center is open", () => {
  const dir = mkdtempSync("/tmp/opencode/cc-network-polling-");
  try {
    writeFileSync(
      `${dir}/netdev`,
      "Inter-| Receive | Transmit\n" +
        " face |bytes packets errs drop fifo frame compressed multicast|bytes packets errs drop fifo colls carrier compressed\n" +
        "  eth0: 100 0 0 0 0 0 0 0 200 0 0 0 0 0 0 0\n",
    );
    Object.assign(process.env, {
      NOTCH_SMOKE: "0",
      NOTCH_CC_URL:
        new URL("../../shell/notches/controlcenter", import.meta.url).href,
      NOTCH_SYSINFO_NETDEV: `${dir}/netdev`,
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
    });
    const result = spawnSync("qs", [
      "-p",
      new URL("./controlcenter-network-polling.qml", import.meta.url).pathname,
    ], { encoding: "utf8", timeout: 8000 });
    assert.equal(result.status, 0, result.stdout + result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
