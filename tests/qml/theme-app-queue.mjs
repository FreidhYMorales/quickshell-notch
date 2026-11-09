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

// App-facing matugen runs are slow on purpose, so a second choice lands while
// the first run is still in flight.
const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'; exit 0 ;;
esac
sleep 0.4
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

function run(wallpaper) {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-queue-");
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
    if (wallpaper) {
      writeFileSync(join(notch, "wallpaper.txt"), wallpaper + "\n");
    }
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-app-queue.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 25000,
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
    return {
      result,
      matugen: readFileSync(matugenLog, "utf8"),
      hook: readFileSync(hookLog, "utf8"),
    };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("a second mode choice waits for the run in flight and wins", () => {
  const { result, matugen, hook } = run("/w/global.png");
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /app queue: applied true/);
  assert.match(
    matugen,
    /^image \/w\/global\.png --type scheme-vibrant --mode dark --source-color-index 0 --quiet$/m,
  );
  assert.match(
    matugen,
    /^image \/w\/global\.png --type scheme-neutral --mode dark --source-color-index 0 --quiet$/m,
  );
  assert.ok(
    matugen.indexOf("scheme-neutral") > matugen.indexOf("scheme-vibrant"),
    matugen,
  );
  assert.equal(hook, "dark\ndark\n");
});

test("a mode choice without a wallpaper does not run matugen", () => {
  const { result, matugen, hook } = run("");
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /app queue: applied true/);
  assert.equal(matugen, "");
  assert.equal(hook, "");
});
