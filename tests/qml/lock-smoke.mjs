import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const shellQml = fileURLToPath(
  new URL("../../shell/shell.qml", import.meta.url),
);
const env = Object.assign({}, process.env, {
  NOTCH_SMOKE: "1",
  QT_QPA_PLATFORM: "wayland",
  NO_COLOR: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test("a smoke run exposes no lock target and never locks", async () => {
  const shell = spawn("timeout", ["8", "qs", "-p", shellQml], { env });
  let output = "";
  shell.stdout.on("data", (chunk) => output += chunk);
  shell.stderr.on("data", (chunk) => output += chunk);
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(3000);
    const show = spawnSync("qs", ["-p", shellQml, "ipc", "show"], {
      encoding: "utf8",
      timeout: 5000,
      env,
    });
    const call = spawnSync(
      "qs",
      ["-p", shellQml, "ipc", "call", "lock", "lock"],
      { encoding: "utf8", timeout: 5000, env },
    );
    await exited;
    assert.match(show.stdout, /target notifs/, show.stdout + show.stderr);
    assert.doesNotMatch(show.stdout, /target lock/, show.stdout);
    assert.match(call.stdout + call.stderr, /Target not found/);
    assert.doesNotMatch(output, /WlSessionLock|session lock/i, output);
  } finally {
    shell.kill();
  }
});
