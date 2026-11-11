import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/test-sddm.sh", import.meta.url),
);

test("synced preview supplies staged configuration without installing a theme", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-preview-");
  const state = join(dir, "state");
  const stage = join(state, "quickshell-notch", "sddm");
  const bin = join(dir, "bin");
  mkdirSync(stage, { recursive: true });
  mkdirSync(bin);
  writeFileSync(join(stage, "theme.conf.user"), "[General]\naccent=#123456\n");
  writeFileSync(
    join(bin, "sddm-greeter-qt6"),
    '#!/bin/sh\n[ "$1" = --test-mode ] && [ "$2" = --theme ] || exit 2\nexec /usr/bin/python3 -c "import pathlib,sys; print((pathlib.Path(sys.argv[1]) / \'theme.conf.user\').read_text())" "$3"\n',
    { mode: 0o755 },
  );
  const result = spawnSync("sh", [script, "--synced"], {
    encoding: "utf8",
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: state,
      PATH: `${bin}:${process.env.PATH}`,
    }),
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /accent=#123456/);
});

test("synced preview reports missing staged data", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-preview-empty-");
  const result = spawnSync("sh", [script, "--synced"], {
    encoding: "utf8",
    timeout: 1500,
    env: Object.assign({}, process.env, { XDG_STATE_HOME: dir }),
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /sync/i);
});

test("synced preview reads the explicitly configured shared directory", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-preview-shared-");
  const shared = join(dir, "shared");
  const bin = join(dir, "bin");
  mkdirSync(shared);
  mkdirSync(bin);
  writeFileSync(join(shared, "theme.conf.user"), "[General]\naccent=#aabbcc\n");
  writeFileSync(
    join(bin, "sddm-greeter-qt6"),
    '#!/bin/sh\nexec /usr/bin/python3 -c "import pathlib,sys; print((pathlib.Path(sys.argv[1]) / \'theme.conf.user\').read_text())" "$3"\n',
    { mode: 0o755 },
  );
  const result = spawnSync("sh", [script, "--synced"], {
    encoding: "utf8",
    env: Object.assign({}, process.env, {
      XDG_STATE_HOME: join(dir, "unused"),
      NOTCH_SDDM_DATA_DIR: shared,
      PATH: `${bin}:${process.env.PATH}`,
    }),
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /accent=#aabbcc/);
});
