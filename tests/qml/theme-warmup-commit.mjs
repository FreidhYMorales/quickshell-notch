import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

// Dry-runs whose colour names the wallpaper they were computed from; the
// app-facing run does nothing.
const matugen = `#!/bin/sh
case " $* " in
  *" --dry-run "*)
    hex=cccccc
    case " $* " in
      *a.png*) hex=aaaaaa ;;
      *b.png*) hex=bbbbbb ;;
    esac
    printf '%s' "{\\"colors\\":{\\"primary\\":{\\"default\\":{\\"color\\":\\"#$hex\\"}},\\"on_surface\\":{\\"default\\":{\\"color\\":\\"#ddeeff\\"}},\\"on_surface_variant\\":{\\"default\\":{\\"color\\":\\"#112233\\"}}}}"
    ;;
esac
`;

function run(shared) {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-warmup-commit-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const wallpapers = join(dir, "wallpapers");
  const notch = join(state, "quickshell-notch");
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(wallpapers, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(wallpapers, "a.png"), "a");
    writeFileSync(join(wallpapers, "b.png"), "b");
    writeFileSync(join(notch, "wallpaper.txt"), join(wallpapers, "a.png"));
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), "#!/bin/sh\n", {
      mode: 0o755,
    });
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-warmup-commit.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 40000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        QS_WALLPAPER_DIR: wallpapers,
        NOTCH_SMOKE: "0",
        NOTCH_SHARED: shared ? "1" : "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        NOTCH_COMPONENTS_URL: new URL("../../shell/components", import.meta.url)
          .href,
        PATH: `${bin}:${process.env.PATH}`,
      }),
    });
    return result.stdout + result.stderr;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("a shared commit rewarms every monitor on the new wallpaper", () => {
  const output = run(true);
  assert.match(output, /before: DP-1 9 #aaaaaa \| DP-2 9 #aaaaaa/);
  assert.match(output, /after: DP-1 9 #bbbbbb \| DP-2 9 #bbbbbb/);
});

test("a per-monitor commit rewarms only that monitor", () => {
  const output = run(false);
  assert.match(output, /before: DP-1 9 #aaaaaa \| DP-2 9 #aaaaaa/);
  assert.match(output, /after: DP-1 9 #bbbbbb \| DP-2 9 #aaaaaa/);
});
