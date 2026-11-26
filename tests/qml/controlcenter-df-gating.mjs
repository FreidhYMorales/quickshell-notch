import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

test("df samples while a control center is open, not after it closes", () => {
  const dir = mkdtempSync("/tmp/opencode/cc-df-gating-");
  const log = `${dir}/calls`;
  try {
    writeFileSync(
      `${dir}/df`,
      `#!/bin/sh
printf '%s\\n' "$*" >> "${log}"
printf '1B-blocks Used Available Use%%\\n100000 25000 70000 25%%\\n'
`,
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      new URL("./controlcenter-df-gating.qml", import.meta.url).pathname,
    ], {
      encoding: "utf8",
      timeout: 10000,
      env: Object.assign({}, process.env, {
        PATH: `${dir}:${process.env.PATH}`,
        NOTCH_SMOKE: "0",
        NOTCH_CC_URL:
          new URL("../../shell/notches/controlcenter", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.deepEqual(readFileSync(log, "utf8").trim().split("\n"), [
      "-B1 --output=size,used,avail,pcent /",
    ]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
