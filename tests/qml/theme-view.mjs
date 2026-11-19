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
  *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'; exit 0 ;;
esac
`;

test("the theme view lists the modes, marks the active one and closes on choose", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-view-");
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
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(
      join(config, "matugen", "post-hook.sh"),
      '#!/bin/sh\nprintf \'%s\\n\' "$1" >> "$HOOK_LOG"\n',
      { mode: 0o755 },
    );
    writeFileSync(matugenLog, "");
    writeFileSync(hookLog, "");
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-view.qml", import.meta.url)),
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
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        PATH: `${bin}:${process.env.PATH}`,
        MATUGEN_LOG: matugenLog,
        HOOK_LOG: hookLog,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /theme view: nine rows, active, placeholder/);
    assert.match(output, /theme view: closed after choose/);
    assert.deepEqual(
      JSON.parse(readFileSync(join(notch, "theme.json"), "utf8")),
      { mode: "scheme-vibrant", variant: "dark" },
    );
    assert.match(
      readFileSync(matugenLog, "utf8"),
      /^image \/w\/global\.png --type scheme-vibrant --mode dark --source-color-index 0 --quiet$/m,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
