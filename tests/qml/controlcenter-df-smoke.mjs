import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

test("smoke mode never invokes df even with an open control center", () => {
  const dir = mkdtempSync("/tmp/opencode/cc-df-smoke-");
  const log = `${dir}/calls`;
  try {
    writeFileSync(`${dir}/df`, `#!/bin/sh\ntouch "${log}"\n`, { mode: 0o755 });
    const result = spawnSync("qs", [
      "-p",
      new URL("./controlcenter-df-smoke.qml", import.meta.url).pathname,
    ], {
      encoding: "utf8",
      timeout: 8000,
      env: Object.assign({}, process.env, {
        PATH: `${dir}:${process.env.PATH}`,
        NOTCH_SMOKE: "1",
        NOTCH_CC_URL:
          new URL("../../shell/notches/controlcenter", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(existsSync(log), false, "df must not run in smoke mode");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
