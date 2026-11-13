import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const rows =
  `[{"modmask":64,"key":"RETURN","description":"Open Terminal"},{"modmask":4,"key":"Q","description":""},{"modmask":12,"key":"F","description":"Toggle Fullscreen Window"}]`;

function probe(mode) {
  const dir = mkdtempSync("/tmp/opencode/notch-keybinds-view-");
  const bin = join(dir, "bin");
  const fake = `#!/bin/sh
if [ "$NOTCH_FAKE_KEYBINDS" = "fail" ]; then
  printf '%s' 'hyprctl: compositor not running'
  exit 1
fi
printf '%s' '${rows}'
`;
  try {
    mkdirSync(bin, { recursive: true });
    writeFileSync(join(bin, "hyprctl"), fake, { mode: 0o755 });
    return spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./launcher-keybinds-view.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        NOTCH_SMOKE: "0",
        NOTCH_FAKE_KEYBINDS: mode,
        NOTCH_LAUNCH_DRY_RUN: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        PATH: `${bin}:${process.env.PATH}`,
      }),
    });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("activating Keybinds lists the registry rows", () => {
  const result = probe("ok");
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /keybinds view: rows with keys and description/);
});

test("a broken registry shows one unavailable line", () => {
  const result = probe("fail");
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /keybinds view: unavailable line shown/);
});
