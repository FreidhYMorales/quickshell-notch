import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("Escape leaves the theme view for the commands unchanged", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-back-");
  try {
    mkdirSync(join(dir, "quickshell-notch"), { recursive: true });
    writeFileSync(
      join(dir, "quickshell-notch", "theme.json"),
      '{"mode":"scheme-neutral"}',
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-back.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: dir,
        XDG_CONFIG_HOME: join(dir, "config"),
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /theme back: commands with mode neutral/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
