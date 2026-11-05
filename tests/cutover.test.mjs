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

// A throwaway mirror of the real layout: Hyprland config, the deployed
// Quickshell config dirs, a state dir and a `qs` that only records its calls.
function fixture({ notchConfig = true } = {}) {
  const dir = mkdtempSync(join(tmpdir(), "cutover-"));
  const hypr = join(dir, "hypr");
  mkdirSync(join(hypr, "deadlock"), { recursive: true });
  writeFileSync(join(hypr, "deadlock", "execs.lua"), EXECS);
  writeFileSync(join(hypr, "deadlock", "keybinds.lua"), KEYBINDS);
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
    qsLog,
    state: join(dir, "state"),
    env: {
      HOME: dir,
      PATH: bin + ":" + process.env.PATH,
      HYPR_DIR: hypr,
      NOTCH_CONFIG_DIR: join(config, "notch"),
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

const read = (...parts) => readFileSync(join(...parts), "utf8");

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

test("a second cutover keeps the original backups", () => {
  const f = fixture();
  try {
    assert.equal(run(f, "cutover").status, 0);
    assert.equal(run(f, "cutover").status, 0);
    assert.equal(read(f.state, "keybinds.lua"), KEYBINDS);
    assert.equal(read(f.state, "execs.lua"), EXECS);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS_AFTER);
    assert.deepEqual(readFileSync(f.qsLog, "utf8").trim().split("\n"), [
      "kill",
      "-c notch -d",
      "kill",
      "-c notch -d",
    ]);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});

test("cutover kills the running shells, remaps the keybinds and starts the notch", () => {
  const f = fixture();
  try {
    const result = run(f, "cutover");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(read(f.hypr, "deadlock", "execs.lua"), EXECS_AFTER);
    assert.equal(read(f.hypr, "deadlock", "keybinds.lua"), KEYBINDS_AFTER);
    assert.equal(read(f.state, "execs.lua"), EXECS);
    assert.equal(read(f.state, "keybinds.lua"), KEYBINDS);
    assert.deepEqual(readFileSync(f.qsLog, "utf8").trim().split("\n"), [
      "kill",
      "-c notch -d",
    ]);
  } finally {
    rmSync(f.dir, { recursive: true, force: true });
  }
});
