import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("hovering the idle notch cross-fades idle out and expanded in", () => {
  mkdirSync("/tmp/opencode", { recursive: true });
  const dir = mkdtempSync("/tmp/opencode/notch-crossfade-open-");
  try {
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./expanded-crossfade-open.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: join(dir, "state"),
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(
      output,
      /crossfade open: mid both partial; settled idle 0 expanded 1 hidden shown/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
