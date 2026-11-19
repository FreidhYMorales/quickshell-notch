import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

// The extracted "frame" holds the video's path, and the dry-run colour names
// the video that frame came from.
const matugen = `#!/bin/sh
case " $* " in
  *" --dry-run "*)
    sleep 0.5
    source=$(cat "$2")
    hex=cccccc
    case "$source" in
      *a.mp4*) hex=aaaaaa ;;
      *b.mp4*) hex=bbbbbb ;;
    esac
    printf '%s' "{\\"colors\\":{\\"primary\\":{\\"default\\":{\\"color\\":\\"#$hex\\"}},\\"on_surface\\":{\\"default\\":{\\"color\\":\\"#ddeeff\\"}},\\"on_surface_variant\\":{\\"default\\":{\\"color\\":\\"#112233\\"}}}}"
    ;;
esac
`;

const ffprobe = `#!/bin/sh
echo 10
`;

// Slow enough that several commits land while frames are being extracted.
const ffmpeg = `#!/bin/sh
for arg; do out="$arg"; done
while [ $# -gt 0 ]; do
  [ "$1" = -i ] && in="$2"
  shift
done
sleep 3
printf '%s' "$in" > "$out"
`;

test("a video never reads a frame another video is still extracting", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-warmup-video-again-");
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
    writeFileSync(join(wallpapers, "a.mp4"), "a");
    writeFileSync(join(wallpapers, "b.mp4"), "b");
    writeFileSync(join(notch, "wallpaper.txt"), join(wallpapers, "a.mp4"));
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(bin, "ffprobe"), ffprobe, { mode: 0o755 });
    writeFileSync(join(bin, "ffmpeg"), ffmpeg, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), "#!/bin/sh\n", {
      mode: 0o755,
    });
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-warmup-video-again.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 240000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        XDG_CACHE_HOME: join(dir, "cache"),
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
    assert.match(output, /first a extracting true$/m);
    assert.match(output, /b extracting true$/m);
    assert.match(output, /settled: DP-1 9 #aaaaaa$/m);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
