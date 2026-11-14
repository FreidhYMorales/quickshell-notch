import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("an unsafe name or an empty URL writes nothing and names the fault", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-webapp-invalid-");
  const bin = join(dir, "bin");
  const marker = join(dir, "ran");
  try {
    mkdirSync(bin, { recursive: true });
    // Leaves a marker behind if the form ever asks the helper to run.
    writeFileSync(
      join(bin, "webapp-install"),
      `#!/bin/sh\n: > "$NOTCH_WEBAPP_MARK"\n`,
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-webapp-invalid.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_WEBAPP_MARK: marker,
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        PATH: `${bin}:${process.env.PATH}`,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /webapp invalid: each fault is named and nothing ran/);
    assert.equal(existsSync(marker), false, "the helper ran on refused input");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
