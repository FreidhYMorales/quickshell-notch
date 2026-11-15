import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("a failing installer reports an error and leaves the form open", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-webapp-failure-");
  try {
    writeFileSync(join(dir, "webapp-install"), "#!/bin/sh\nexit 42\n", {
      mode: 0o755,
    });
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-webapp-failure.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        PATH: `${dir}:${process.env.PATH}`,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /webapp failure: reported and form remains open/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
