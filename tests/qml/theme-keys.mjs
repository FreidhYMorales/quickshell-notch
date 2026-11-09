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

const matugen = `#!/bin/sh
case " $* " in
  *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#aabbcc"}},"on_surface":{"default":{"color":"#ddeeff"}},"on_surface_variant":{"default":{"color":"#112233"}}}}'; exit 0 ;;
esac
`;

test("arrows move through the theme list and Enter chooses", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-theme-keys-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const notch = join(state, "quickshell-notch");
  try {
    mkdirSync(notch, { recursive: true });
    mkdirSync(bin, { recursive: true });
    mkdirSync(join(config, "matugen"), { recursive: true });
    writeFileSync(join(notch, "wallpaper.txt"), "/w/global.png\n");
    writeFileSync(join(notch, "theme.json"), '{"mode":"scheme-content"}');
    writeFileSync(join(bin, "matugen"), matugen, { mode: 0o755 });
    writeFileSync(
      join(config, "matugen", "post-hook.sh"),
      "#!/bin/sh\nexit 0\n",
      { mode: 0o755 },
    );
    const result = spawnSync(qs, [
      "-p",
      fileURLToPath(new URL("./theme-keys.qml", import.meta.url)),
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
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
        PATH: `${bin}:${process.env.PATH}`,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /theme keys: chose scheme-neutral, closed true/);
    assert.deepEqual(
      JSON.parse(readFileSync(join(notch, "theme.json"), "utf8")),
      { mode: "scheme-neutral" },
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
