import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

test("a missing matugen does not wedge the theme queues", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-missing-");
  try {
    mkdirSync(join(dir, "quickshell-notch"), { recursive: true });
    mkdirSync(join(dir, "empty-path"), { recursive: true });
    writeFileSync(
      join(dir, "quickshell-notch", "wallpaper.txt"),
      "/w/global.png\n",
    );
    writeFileSync(
      join(dir, "quickshell-notch", "wallpaper-screens.json"),
      '{"DP-1":"/w/a.png"}',
    );
    writeFileSync(
      join(dir, "quickshell-notch", "theme.json"),
      '{"mode":"scheme-content"}',
    );
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-missing-matugen.qml", import.meta.url)),
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
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        PATH: join(dir, "empty-path"),
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /missing matugen: applied true, queues idle/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
