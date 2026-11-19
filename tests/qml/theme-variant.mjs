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

// A matugen that records its argv, prints one dry-run palette and writes a
// colors.json for the app-facing run.
const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*)
    printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'
    exit 0
    ;;
esac
mkdir -p "$XDG_CONFIG_HOME/matugen"
printf '%s' '{"colors":{"primary":{"hex":"#aabbcc"},"on_surface":{"hex":"#ddeeff"},"on_surface_variant":{"hex":"#112233"}}}' > "$XDG_CONFIG_HOME/matugen/colors.json"
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

test("switching to light reruns only the apps in light and saves the variant", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-variant-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const notch = join(state, "quickshell-notch");
  const old = join(state, "quickshell");
  const matugenLog = join(dir, "matugen.log");
  const hookLog = join(dir, "hook.log");
  const oldTheme = '{"mode":"scheme-rainbow","dynamic":false}';
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(old, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(notch, "wallpaper.txt"), "/w/global.png\n");
    writeFileSync(
      join(notch, "wallpaper-screens.json"),
      '{"DP-1":"/w/a.png"}',
    );
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(old, "theme.json"), oldTheme);
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-variant.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        PATH: `${bin}:${process.env.PATH}`,
        MATUGEN_LOG: matugenLog,
        HOOK_LOG: hookLog,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /theme variant: light/);
    assert.deepEqual(
      JSON.parse(readFileSync(join(notch, "theme.json"), "utf8")),
      { mode: "scheme-content", variant: "light" },
    );
    assert.equal(readFileSync(join(old, "theme.json"), "utf8"), oldTheme);
    const log = readFileSync(matugenLog, "utf8");
    assert.match(
      log,
      /^image \/w\/global\.png --type scheme-content --mode light --source-color-index 0 --quiet$/m,
    );
    // The override was dry-run once at startup; the switch never reruns it.
    assert.equal(log.match(/^image \/w\/a\.png .*--dry-run/gm).length, 1);
    assert.equal(readFileSync(hookLog, "utf8"), "light\n");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
