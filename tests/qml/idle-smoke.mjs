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
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("a smoke run neither imports nor writes the idle state", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-idle-smoke-"));
  try {
    mkdirSync(join(dir, "quickshell"));
    writeFileSync(
      join(dir, "quickshell", "idle.json"),
      '{"screensaverTimeoutMin":1,"lockTimeoutMin":5,"suspendTimeoutMin":15}',
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./idle-import.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: dir,
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.match(output, /idle timeouts: 3\/5\/15/, output);
    assert.equal(existsSync(join(dir, "quickshell-notch")), false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
