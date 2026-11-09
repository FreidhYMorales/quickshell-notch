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

const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*)
    printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'
    exit 0
    ;;
esac
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

// Runs the probe with two wallpapers; it commits the last entry (b.png) for
// DP-1, shared or as an override, and waits for the theme pipeline.
function run(shared) {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-wallpaper-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const wallpapers = join(dir, "wallpapers");
  const notch = join(state, "quickshell-notch");
  const matugenLog = join(dir, "matugen.log");
  const hookLog = join(dir, "hook.log");
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(wallpapers, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(wallpapers, "a.png"), "a");
    writeFileSync(join(wallpapers, "b.png"), "b");
    writeFileSync(join(notch, "wallpaper.txt"), join(wallpapers, "a.png"));
    writeFileSync(
      join(notch, "wallpaper-screens.json"),
      JSON.stringify({ "DP-1": join(wallpapers, "a.png") }),
    );
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-tonal-spot"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-wallpaper.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        QS_WALLPAPER_DIR: wallpapers,
        NOTCH_SMOKE: "0",
        THEME_PROBE_SHARED: shared ? "1" : "0",
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
    return {
      result,
      matugen: readFileSync(matugenLog, "utf8"),
      hook: readFileSync(hookLog, "utf8"),
      chosen: join(wallpapers, "b.png"),
    };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("a shared wallpaper commit re-themes the apps", () => {
  const { result, matugen, hook, chosen } = run(true);
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /theme commit applied: true/);
  assert.match(
    matugen,
    new RegExp(
      `^image ${chosen} --type scheme-tonal-spot --mode dark --source-color-index 0 --quiet$`,
      "m",
    ),
  );
  // The saved DP-1 override is rebuilt at startup; the shared commit itself
  // must not run a dry-run for the new wallpaper.
  assert.doesNotMatch(
    matugen,
    new RegExp(`^image ${chosen} .*--dry-run`, "m"),
  );
  assert.equal(
    matugen.split("\n").filter((line) => line.includes("--dry-run")).length,
    1,
    matugen,
  );
  assert.equal(hook, "dark\n");
});

test("a per-monitor commit only recolours that monitor", () => {
  const { result, matugen, hook, chosen } = run(false);
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /theme commit applied: true/);
  assert.match(
    matugen,
    new RegExp(
      `^image ${chosen} --type scheme-tonal-spot --mode dark --source-color-index 0 --dry-run --quiet --json hex$`,
      "m",
    ),
  );
  assert.doesNotMatch(matugen, / --source-color-index 0 --quiet$/m);
  assert.equal(hook, "");
});
