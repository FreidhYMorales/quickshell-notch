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
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("installing runs the helper with the name and URL as separate arguments and confirms it", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-webapp-install-");
  const bin = join(dir, "bin");
  const argsFile = join(dir, "args");
  try {
    mkdirSync(bin, { recursive: true });
    // Records what it was called with, one argument per line.
    writeFileSync(
      join(bin, "webapp-install"),
      `#!/bin/sh\nprintf '%s\\n%s\\n' "$1" "$2" > "$NOTCH_WEBAPP_ARGS"\n`,
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-webapp-install.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_WEBAPP_ARGS: argsFile,
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
    assert.match(output, /webapp install: helper ran and the notch confirmed/);
    assert.equal(
      readFileSync(argsFile, "utf8"),
      "Notch Docs\nhttps://example.com\n",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
