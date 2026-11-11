import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

for (const shared of [true, false]) {
  test(`a ${shared ? "shared" : "per-monitor"} wallpaper update stages the SDDM theme`, () => {
    const dir = mkdtempSync("/tmp/opencode/theme-sddm-");
    const state = join(dir, "state");
    const config = join(dir, "config");
    const bin = join(dir, "bin");
    const images = join(dir, "images");
    const greetdOutput = join(dir, "greetd");
    const sddmOutput = shared
      ? join(state, "quickshell-notch", "sddm")
      : join(dir, "shared-sddm");
    for (
      const path of [
        join(state, "quickshell-notch"),
        join(config, "matugen"),
        bin,
        images,
        greetdOutput,
      ]
    ) mkdirSync(path, { recursive: true });
    if (!shared) {
      writeFileSync(
        join(state, "quickshell-notch", "sddm-target.txt"),
        sddmOutput + "\n",
      );
    }
    writeFileSync(
      join(state, "quickshell-notch", "greetd-target.txt"),
      greetdOutput + "\n",
    );
    writeFileSync(join(images, "a.png"), "first");
    writeFileSync(join(images, "b.png"), "second");
    writeFileSync(
      join(state, "quickshell-notch", "wallpaper.txt"),
      join(images, "a.png"),
    );
    writeFileSync(
      join(bin, "matugen"),
      `#!/bin/sh\ncase " $* " in *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#123456"}},"on_surface":{"default":{"color":"#abcdef"}},"on_surface_variant":{"default":{"color":"#8899aa"}}}}';; *) printf '%s' '{"colors":{"primary":{"hex":"#123456"},"on_surface":{"hex":"#abcdef"}}}' > "$XDG_CONFIG_HOME/matugen/colors.json";; esac\n`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(config, "matugen", "post-hook.sh"),
      "#!/bin/sh\nexit 0\n",
      { mode: 0o755 },
    );
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./theme-wallpaper.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: state,
        XDG_CONFIG_HOME: config,
        QS_WALLPAPER_DIR: images,
        NOTCH_SMOKE: "0",
        THEME_PROBE_SHARED: shared ? "1" : "0",
        NOTCH_SDDM_DATA_DIR: "",
        NOTCH_GREETD_DATA_DIR: "",
        QT_QPA_PLATFORM: "wayland",
        QS_DISABLE_CRASH_HANDLER: "1",
        NO_COLOR: "1",
        PATH: `${bin}:${process.env.PATH}`,
        NOTCH_SERVICES_URL:
          new URL("../../shell/services", import.meta.url).href,
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      readFileSync(
        join(sddmOutput, "theme.conf.user"),
        "utf8",
      ),
      /accent=#123456/,
    );
    const configText = readFileSync(
      join(sddmOutput, "theme.conf.user"),
      "utf8",
    );
    assert.equal(
      readFileSync(
        fileURLToPath(configText.match(/^background=(.+)$/m)[1]),
        "utf8",
      ),
      "second",
    );
    const visual = JSON.parse(
      readFileSync(join(greetdOutput, "visual.json"), "utf8"),
    );
    assert.equal(visual.accent, "#123456");
    assert.equal(visual.foreground, "#abcdef");
    assert.equal(
      readFileSync(join(greetdOutput, visual.background), "utf8"),
      "second",
    );
  });
}

test("a failing greetd publisher does not prevent SDDM staging", () => {
  const dir = mkdtempSync("/tmp/opencode/theme-greetd-fail-");
  const state = join(dir, "state");
  const config = join(dir, "config");
  const bin = join(dir, "bin");
  const images = join(dir, "images");
  for (
    const path of [
      join(state, "quickshell-notch"),
      join(config, "matugen"),
      bin,
      images,
    ]
  ) mkdirSync(path, { recursive: true });
  writeFileSync(join(images, "a.png"), "first");
  writeFileSync(join(images, "b.png"), "second");
  writeFileSync(
    join(state, "quickshell-notch", "wallpaper.txt"),
    join(images, "a.png"),
  );
  writeFileSync(
    join(bin, "matugen"),
    `#!/bin/sh\ncase " $* " in *" --dry-run "*) printf '%s' '{"colors":{"primary":{"default":{"color":"#123456"}},"on_surface":{"default":{"color":"#abcdef"}},"on_surface_variant":{"default":{"color":"#8899aa"}}}}';; *) printf '%s' '{"colors":{"primary":{"hex":"#123456"},"on_surface":{"hex":"#abcdef"}}}' > "$XDG_CONFIG_HOME/matugen/colors.json";; esac\n`,
    { mode: 0o755 },
  );
  writeFileSync(
    join(config, "matugen", "post-hook.sh"),
    "#!/bin/sh\nexit 0\n",
    { mode: 0o755 },
  );
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./theme-wallpaper.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 20000,
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: state,
      XDG_CONFIG_HOME: config,
      QS_WALLPAPER_DIR: images,
      NOTCH_SMOKE: "0",
      THEME_PROBE_SHARED: "1",
      NOTCH_SDDM_DATA_DIR: "",
      NOTCH_GREETD_DATA_DIR: join(dir, "missing"),
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
      NO_COLOR: "1",
      PATH: `${bin}:${process.env.PATH}`,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    }),
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /greetd staging exited/);
  assert.match(
    readFileSync(
      join(state, "quickshell-notch", "sddm", "theme.conf.user"),
      "utf8",
    ),
    /accent=#123456/,
  );
});

test("a queued greetd update snapshots the palette before colors.json changes", () => {
  const dir = mkdtempSync("/tmp/opencode/theme-greetd-palette-");
  writeFileSync(
    join(dir, "colors.json"),
    '{"colors":{"primary":{"hex":"#123456"},"on_surface":{"hex":"#abcdef"}}}',
  );
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./theme-greetd-queue.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 10000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      QT_QPA_PLATFORM: "offscreen",
      QS_DISABLE_CRASH_HANDLER: "1",
      NO_COLOR: "1",
      NOTCH_GREETD_DATA_DIR: dir,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    }),
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout + result.stderr, /greetd queued palette: #123456/);
});
