import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const binds = [];
for (let i = 1; i <= 12; i++) {
  binds.push({ modmask: 64, key: `F${i}`, description: `Action ${i}` });
}
const rows = JSON.stringify(binds);

test("the keybinds cursor follows the pointer and arrows and Esc leaves", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-keybinds-keys-");
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
      fileURLToPath(new URL("./launcher-keybinds-keys.qml", import.meta.url)),
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
        PATH: `${bin}:${process.env.PATH}`,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /keybinds keys: cursor, scroll and escape/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
