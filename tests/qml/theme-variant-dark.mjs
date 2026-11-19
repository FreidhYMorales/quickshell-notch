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

// A matugen whose app-facing runs write their own light or dark colors.json,
// both unlike the dark palette every dry-run prints.
const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*)
    printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'
    exit 0
    ;;
esac
mkdir -p "$XDG_CONFIG_HOME/matugen"
case " $* " in
  *" --mode light "*)
    printf '%s' '{"colors":{"primary":{"hex":"#f0f0f0"},"on_surface":{"hex":"#101010"},"on_surface_variant":{"hex":"#202020"}}}' > "$XDG_CONFIG_HOME/matugen/colors.json"
    ;;
  *)
    printf '%s' '{"colors":{"primary":{"hex":"#445566"},"on_surface":{"hex":"#ddeeff"},"on_surface_variant":{"hex":"#112233"}}}' > "$XDG_CONFIG_HOME/matugen/colors.json"
    ;;
esac
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

test("back in dark the notch follows the apps' colors.json again", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-variant-dark-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const notch = join(state, "quickshell-notch");
  const matugenLog = join(dir, "matugen.log");
  const hookLog = join(dir, "hook.log");
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(notch, "wallpaper.txt"), "/w/global.png\n");
    writeFileSync(join(notch, "wallpaper-screens.json"), "{}");
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-variant-dark.qml", import.meta.url)),
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
        NOTCH_CONFIG_URL: new URL("../../shell/config", import.meta.url).href,
        PATH: `${bin}:${process.env.PATH}`,
        MATUGEN_LOG: matugenLog,
        HOOK_LOG: hookLog,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    // The apps really went back to dark.
    assert.equal(
      JSON.parse(readFileSync(join(config, "matugen", "colors.json"), "utf8"))
        .colors.primary.hex,
      "#445566",
    );
    assert.equal(readFileSync(hookLog, "utf8"), "light\ndark\n");
    assert.match(output, /notch primary: #445566/);
    assert.match(output, /notch global: #445566/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
