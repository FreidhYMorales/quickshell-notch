import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/notch-cutover.sh", import.meta.url),
);

// A throwaway mirror of the real layout: Hyprland config, the deployed
// Quickshell config dirs, a state dir and a `qs` that only records its calls.
function fixture({ notchConfig = true } = {}) {
  const dir = mkdtempSync("/tmp/opencode/cutover-");
  const hypr = join(dir, "hypr");
  mkdirSync(join(hypr, "deadlock"), { recursive: true });
  const config = join(dir, "config", "quickshell");
  if (notchConfig) {
    mkdirSync(join(config, "notch"), { recursive: true });
    writeFileSync(join(config, "notch", "shell.qml"), "// notch\n");
  }
  const bin = join(dir, "bin");
  mkdirSync(bin, { recursive: true });
  const qsLog = join(dir, "qs.log");
  writeFileSync(
    join(bin, "qs"),
    `#!/usr/bin/env bash\nprintf '%s\\n' "$*" >> "${qsLog}"\n`,
  );
  chmodSync(join(bin, "qs"), 0o755);
  return {
    dir,
    hypr,
    config,
    bin,
    qsLog,
    state: join(dir, "state"),
    env: {
      HOME: dir,
      PATH: bin + ":" + process.env.PATH,
      HYPR_DIR: hypr,
      NOTCH_CONFIG_DIR: config,
      STATE_DIR: join(dir, "state"),
      QS: join(bin, "qs"),
    },
  };
}

function run(f, subcommand) {
  return spawnSync("bash", [script, subcommand], {
    encoding: "utf8",
    env: Object.assign({}, process.env, f.env),
    timeout: 10000,
  });
}

test("cutover refuses to run without the deployed notch config", () => {
  const f = fixture({ notchConfig: false });
  try {
    const result = run(f, "cutover");
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stderr, /notch config not found/);
    assert.equal(existsSync(f.state), false);
    assert.equal(existsSync(f.qsLog) ? readFileSync(f.qsLog, "utf8") : "", "");
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});
