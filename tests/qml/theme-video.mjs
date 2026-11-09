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

// matugen cannot read a video: the stub records what it was given, the frame
// tools record their argv and write the still frame.
const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'; exit 0 ;;
esac
`;

const ffprobe = `#!/bin/sh
printf '%s\\n' "$*" >> "$FFPROBE_LOG"
printf '10.0\\n'
`;

const ffmpeg = `#!/bin/sh
printf '%s\\n' "$*" >> "$FFMPEG_LOG"
for arg in "$@"; do out=$arg; done
printf 'png' > "$out"
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

test("a video wallpaper is themed from its middle frame", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-video-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const cache = join(dir, "cache");
  const bin = join(dir, "bin");
  const notch = join(state, "quickshell-notch");
  const logs = {
    matugen: join(dir, "matugen.log"),
    ffprobe: join(dir, "ffprobe.log"),
    ffmpeg: join(dir, "ffmpeg.log"),
    hook: join(dir, "hook.log"),
  };
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(cache, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(notch, "wallpaper.txt"), "/w/clip.mp4\n");
    writeFileSync(
      join(notch, "wallpaper-screens.json"),
      '{"DP-1":"/w/clip.mp4"}',
    );
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(bin, "ffprobe"), ffprobe, { mode: 0o755 });
    writeFileSync(join(bin, "ffmpeg"), ffmpeg, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    for (const path of Object.values(logs)) writeFileSync(path, "");
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-video.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 30000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        XDG_CACHE_HOME: cache,
        NOTCH_SMOKE: "0",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        PATH: `${bin}:${process.env.PATH}`,
        MATUGEN_LOG: logs.matugen,
        FFPROBE_LOG: logs.ffprobe,
        FFMPEG_LOG: logs.ffmpeg,
        HOOK_LOG: logs.hook,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /theme video: applied true, previews 9/);
    assert.match(readFileSync(logs.ffprobe, "utf8"), /\/w\/clip\.mp4$/m);
    const frames = readFileSync(logs.ffmpeg, "utf8").trim().split("\n");
    assert.equal(frames.length, 3, frames.join("\n"));
    for (const line of frames) {
      assert.match(line, /(^| )-ss 5( |$)/, line);
      assert.match(line, /\/w\/clip\.mp4 /, line);
    }
    assert.ok(
      frames.some((line) => /theme-frame-app\.png$/.test(line)),
      frames.join("\n"),
    );
    assert.ok(
      frames.some((line) => /theme-frame-palette\.png$/.test(line)),
      frames.join("\n"),
    );
    assert.ok(
      frames.some((line) => /theme-frame-preview\.png$/.test(line)),
      frames.join("\n"),
    );
    const runs = readFileSync(logs.matugen, "utf8");
    assert.doesNotMatch(runs, /\.mp4/);
    assert.match(
      runs,
      /^image .*theme-frame-app\.png --type scheme-vibrant --mode dark --source-color-index 0 --quiet$/m,
    );
    assert.match(
      runs,
      /^image .*theme-frame-palette\.png --type scheme-vibrant --mode dark --source-color-index 0 --dry-run --quiet --json hex$/m,
    );
    assert.match(
      runs,
      /^image .*theme-frame-preview\.png --type scheme-content --mode dark --source-color-index 0 --dry-run --quiet --json hex$/m,
    );
    assert.equal(readFileSync(logs.hook, "utf8"), "dark\n");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
