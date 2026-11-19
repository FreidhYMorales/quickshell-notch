import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

// Slow dry-runs whose colour names the wallpaper they were computed from, so
// a commit can land while the second monitor is still warming.
const matugen = `#!/bin/sh
case " $* " in
  *" --dry-run "*)
    sleep 0.3
    hex=cccccc
    case " $* " in
      *a.png*) hex=aaaaaa ;;
      *b.png*) hex=bbbbbb ;;
    esac
    printf '%s' "{\\"colors\\":{\\"primary\\":{\\"default\\":{\\"color\\":\\"#$hex\\"}},\\"on_surface\\":{\\"default\\":{\\"color\\":\\"#ddeeff\\"}},\\"on_surface_variant\\":{\\"default\\":{\\"color\\":\\"#112233\\"}}}}"
    ;;
esac
`;

test("a commit on one monitor never strands another one's warm-up", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-warmup-race-");
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
      fileURLToPath(new URL("./theme-warmup-race.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 60000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        QS_WALLPAPER_DIR: wallpapers,
        NOTCH_SMOKE: "0",
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
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /at commit: DP-2 [2-8]$/m);
    assert.match(output, /settled: DP-1 9 #bbbbbb \| DP-2 9 #aaaaaa/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
