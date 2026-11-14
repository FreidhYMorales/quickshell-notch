import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const rows =
  `[{"modmask":64,"key":"RETURN","description":"Open Terminal"},{"modmask":12,"key":"F","description":"Toggle Fullscreen Window"},{"modmask":64,"key":"B","description":"Open or focus Browser"}]`;

test("typing narrows the keybinds rows without resizing the notch", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-keybinds-filter-");
  const bin = join(dir, "bin");
  try {
    mkdirSync(bin, { recursive: true });
    writeFileSync(
      join(bin, "hyprctl"),
      `#!/bin/sh\nprintf '%s' '${rows}'\n`,
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-keybinds-filter.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_LAUNCH_DRY_RUN: "1",
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
    assert.match(output, /keybinds filter: narrows, empties and restores/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
