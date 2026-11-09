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

// A dry-run takes half a second, so a shared commit lands while the palette
// for the override it clears is still being computed.
const matugen = `#!/bin/sh
printf '%s\\n' "$*" >> "$MATUGEN_LOG"
case " $* " in
  *" --dry-run "*) sleep 0.5; printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'; exit 0 ;;
esac
`;

const postHook = `#!/bin/sh
printf '%s\\n' "$1" >> "$HOOK_LOG"
`;

test("a shared commit discards the palette still in flight", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-epoch-");
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
    writeFileSync(
      join(notch, "wallpaper-screens.json"),
      '{"DP-1":"/w/old.png"}',
    );
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-neutral"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(join(config, "matugen", "post-hook.sh"), postHook, {
      mode: 0o755,
    });
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-epoch.qml", import.meta.url)),
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
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /shared commit: applied true, DP-1 palette none/);
    const runs = readFileSync(matugenLog, "utf8");
    assert.match(
      runs,
      /^image \/w\/old\.png --type scheme-neutral --mode dark --source-color-index 0 --dry-run --quiet --json hex$/m,
    );
    assert.match(
      runs,
      /^image \/w\/new\.png --type scheme-neutral --mode dark --source-color-index 0 --quiet$/m,
    );
    assert.equal(readFileSync(hookLog, "utf8"), "dark\n");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
