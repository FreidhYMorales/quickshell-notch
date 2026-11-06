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
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/notch-cutover.sh", import.meta.url),
);

// Small copies of the real Hyprland files: only the lines the cutover owns,
// plus one unrelated keybind that must survive untouched.
const EXECS = `-- Autostart

local exec = hl.exec_cmd

local quickshell = "quickshell"

hl.on("hyprland.start", function()
\texec(quickshell)
end)
`;

const EXECS_AFTER = `-- Autostart

local exec = hl.exec_cmd

local quickshell = "qs -c notch"

hl.on("hyprland.start", function()
\texec(quickshell)
end)
`;

const KEYBINDS = `-- Keybinds Configs

local keybind = hl.bind
local exec = hl.dsp.exec_cmd

local mainMod = "SUPER"

keybind(mainMod .. " + RETURN", exec(terminal), descrip("Open Terminal"))

-- Quickshell panels
local qsIpc = "qs ipc call"

keybind(mainMod .. " + SPACE", exec(qsIpc .. " launcher toggle"), descrip("Toggle Launcher"))
keybind(mainMod .. " + D", exec(qsIpc .. " dashboard toggle"), descrip("Toggle Dashboard"))
keybind(mainMod .. " + N", exec(qsIpc .. " notifications toggle"), descrip("Toggle Notifications"))
keybind(mainMod .. " + ALT + C", exec(qsIpc .. " calendar toggle"), descrip("Toggle Calendar"))
keybind("CTRL + ALT + DELETE", exec(qsIpc .. " powermenu toggle"), descrip("Toggle Power Menu"))
keybind("XF86PowerOff", exec("qs ipc call lock lock"), { description = "Power button: lock screen" })
`;

const KEYBINDS_AFTER = `-- Keybinds Configs

local keybind = hl.bind
local exec = hl.dsp.exec_cmd

local mainMod = "SUPER"

keybind(mainMod .. " + RETURN", exec(terminal), descrip("Open Terminal"))

-- Quickshell panels
local qsIpc = "qs -c notch ipc call"

keybind(mainMod .. " + SPACE", exec(qsIpc .. " launcher toggle"), descrip("Toggle Launcher"))
keybind(mainMod .. " + D", exec(qsIpc .. " controlcenter open"), descrip("Open Control Center"))
keybind(mainMod .. " + N", exec(qsIpc .. " controlcenter notifications"), descrip("Open Notifications"))
keybind(mainMod .. " + ALT + C", exec(qsIpc .. " expanded toggle"), descrip("Toggle Expanded Notch"))
keybind("CTRL + ALT + DELETE", exec(qsIpc .. " power open"), descrip("Open Power Menu"))
keybind("XF86PowerOff", exec("qs -c notch ipc call lock lock"), { description = "Power button: lock screen" })
`;

// A `qs` that keeps the list of live instances in a file, like the real one
// keeps them in its run dir: `list --all` prints them, `kill --pid` drops one
// and a launch adds one. Tests seed instances to model the old bar, a dev
// `qs -p` run or a stray instance that refuses to die.
const FAKE_QS = `#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$QS_LOG"
case "$1" in
list)
    while read -r pid config; do
        printf 'Instance i%s:\\n  Process ID: %s\\n  Config path: %s\\n' "$pid" "$pid" "$config"
    done < "$QS_STATE"
    ;;
kill)
    if [[ -z "\${QS_IGNORE_KILL:-}" ]]; then
        grep -v "^$3 " "$QS_STATE" >"$QS_STATE.tmp" || true
        mv "$QS_STATE.tmp" "$QS_STATE"
    fi
    ;;
*)
    next=$(cat "$QS_NEXT")
    echo $((next + 1)) >"$QS_NEXT"
    if [[ "$1" == "-c" && "$2" == "notch" ]]; then
        config="$NOTCH_CONFIG_DIR/shell.qml"
    else
        config="$QS_DEFAULT_CONFIG"
    fi
    printf '%s %s\\n' "$next" "$config" >>"$QS_STATE"
    if [[ "$1" == "-c" && "\${QS_DOUBLE_START:-}" == "1" ]]; then
        printf '%s %s\\n' "$((next + 1))" "$QS_STRAY_CONFIG" >>"$QS_STATE"
    fi
    ;;
esac
`;

// A throwaway mirror of the real layout: Hyprland config, the deployed
// Quickshell config dirs, a state dir and the fake `qs` above.
function fixture(
  { notchConfig = true, keybinds = KEYBINDS, execs = EXECS } = {},
) {
  const dir = mkdtempSync(join(tmpdir(), "cutover-"));
  const hypr = join(dir, "hypr");
  mkdirSync(join(hypr, "deadlock"), { recursive: true });
  writeFileSync(join(hypr, "deadlock", "execs.lua"), execs);
  writeFileSync(join(hypr, "deadlock", "keybinds.lua"), keybinds);
  const config = join(dir, "config", "quickshell");
  if (notchConfig) {
    mkdirSync(join(config, "notch"), { recursive: true });
    writeFileSync(join(config, "notch", "shell.qml"), "// notch\n");
  }
  const bin = join(dir, "bin");
  mkdirSync(bin, { recursive: true });
  const qsLog = join(dir, "qs.log");
  const instances = join(dir, "instances");
  const next = join(dir, "next");
  writeFileSync(instances, "");
  writeFileSync(next, "1000\n");
  writeFileSync(join(bin, "qs"), FAKE_QS);
  chmodSync(join(bin, "qs"), 0o755);
  return {
    dir,
    hypr,
    config,
    qsLog,
    instances,
    notchConfig: join(config, "notch", "shell.qml"),
    defaultConfig: join(config, "default", "shell.qml"),
    strayConfig: join(dir, "dev", "shell.qml"),
    state: join(dir, "state"),
    env: {
      HOME: dir,
      PATH: bin + ":" + process.env.PATH,
      HYPR_DIR: hypr,
      NOTCH_CONFIG_DIR: join(config, "notch"),
      STATE_DIR: join(dir, "state"),
      QS: join(bin, "qs"),
      QS_LOG: qsLog,
      QS_STATE: instances,
      QS_NEXT: next,
      QS_DEFAULT_CONFIG: join(config, "default", "shell.qml"),
    },
  };
}

function run(f, subcommand, extraEnv = {}) {
  return spawnSync("bash", [script, subcommand], {
    encoding: "utf8",
    env: Object.assign({}, process.env, f.env, extraEnv),
    timeout: 10000,
  });
}

const read = (...parts) => readFileSync(join(...parts), "utf8");
const running = (f) =>
  read(f.instances)
    .split("\n")
    .filter(Boolean)
    .map((line) => line.split(" ")[1]);

function seed(f, configs) {
  writeFileSync(
    f.instances,
    configs.map((config, i) => `${2000 + i} ${config}`).join("\n") + "\n",
  );
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

test("cutover stops the old bar and every other instance before starting the notch", () => {
  const f = fixture();
  try {
    seed(f, [join(f.config, "shell.qml"), f.strayConfig]);
    const result = run(f, "cutover");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.deepEqual(running(f), [f.notchConfig]);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), EXECS_AFTER);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS_AFTER);
    assert.equal(read(f.state, "execs.lua"), EXECS);
    assert.equal(read(f.state, "keybinds.lua"), KEYBINDS);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("a second cutover keeps the original backups", () => {
  const f = fixture();
  try {
    assert.equal(run(f, "cutover").status, 0);
    assert.equal(run(f, "cutover").status, 0);
    assert.equal(read(f.state, "keybinds.lua"), KEYBINDS);
    assert.equal(read(f.state, "execs.lua"), EXECS);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS_AFTER);
    assert.deepEqual(running(f), [f.notchConfig]);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("rollback restores the files, swaps to the old bar and repeats as a no-op", () => {
  const f = fixture();
  try {
    assert.equal(run(f, "cutover").status, 0);
    const result = run(f, "rollback");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), EXECS);
    assert.deepEqual(running(f), [f.defaultConfig]);
    const again = run(f, "rollback");
    assert.equal(again.status, 0, again.stdout + again.stderr);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.deepEqual(running(f), [f.defaultConfig]);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("cutover refuses to start while another instance is still running", () => {
  const f = fixture();
  try {
    seed(f, [join(f.config, "shell.qml")]);
    const result = run(f, "cutover", {
      QS_IGNORE_KILL: "1",
      WAIT_STEPS: "1",
      WAIT_INTERVAL: "0",
    });
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stderr, /still running/);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.deepEqual(running(f), [join(f.config, "shell.qml")]);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("cutover refuses to finish when a second instance appears", () => {
  const f = fixture();
  try {
    const result = run(f, "cutover", {
      QS_DOUBLE_START: "1",
      WAIT_STEPS: "1",
      WAIT_INTERVAL: "0",
    });
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stderr, /one Quickshell instance/);
    assert.equal(running(f).length, 2);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("cutover fails cleanly and keeps the keybinds when they do not match", () => {
  const drifted = KEYBINDS.replace("dashboard toggle", "dashboard open");
  const f = fixture({ keybinds: drifted });
  try {
    const result = run(f, "cutover");
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stderr, /keybinds not remapped/);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), drifted);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), EXECS);
    assert.deepEqual(running(f), []);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("cutover fails cleanly and keeps the autostart when it does not match", () => {
  const drifted = EXECS.replace(
    'local quickshell = "quickshell"',
    'local quickshell = "qs"',
  );
  const f = fixture({ execs: drifted });
  try {
    const result = run(f, "cutover");
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stderr, /autostart not remapped/);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), drifted);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.deepEqual(running(f), []);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("a cutover retried after a failed run keeps the fixed files as the rollback target", () => {
  const drifted = KEYBINDS.replace("dashboard toggle", "dashboard open");
  const f = fixture({ keybinds: drifted });
  try {
    assert.equal(run(f, "cutover").status, 1);
    writeFileSync(join(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.equal(run(f, "cutover").status, 0);
    assert.equal(run(f, "rollback").status, 0);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), EXECS);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});
