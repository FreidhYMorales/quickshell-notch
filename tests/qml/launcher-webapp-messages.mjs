import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("missing name and invalid URL are identified without installing", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-webapp-messages-");
  const marker = join(dir, "ran");
  try {
    writeFileSync(
      join(dir, "webapp-install"),
      '#!/bin/sh\n: > "$NOTCH_WEBAPP_MARK"\n',
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-webapp-messages.qml", import.meta.url)),
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
        PATH: `${dir}:${process.env.PATH}`,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /webapp messages: missing name and invalid URL/);
    assert.equal(
      existsSync(marker),
      false,
      "the installer ran on invalid input",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
