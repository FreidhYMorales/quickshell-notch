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

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

test("a broken theme file is rewritten instead of trusted", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-broken-");
  const state = join(dir, "state");
  const notch = join(state, "quickshell-notch");
  const old = join(state, "quickshell");
  const broken = '{"mode":';
  const oldTheme = '{"mode":"scheme-vibrant","dynamic":true}';
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(old, { recursive: true });
    writeFileSync(join(notch, "theme.json"), broken);
    writeFileSync(join(old, "theme.json"), oldTheme);
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-broken-state.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: join(dir, "config"),
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /broken state: mode scheme-content, saved true/);
    assert.equal(
      readFileSync(join(notch, "theme.json"), "utf8"),
      '{"mode":"scheme-content","variant":"dark"}',
    );
    assert.equal(readFileSync(join(old, "theme.json"), "utf8"), oldTheme);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
