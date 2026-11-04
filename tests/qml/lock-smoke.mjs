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
  // Talk only to this instance (--pid): a live notch from the same path must
  // not answer for it.
  const shell = spawn("qs", ["-p", shellQml], { env });
  const stop = setTimeout(() => shell.kill(), 8000);
  let output = "";
  shell.stdout.on("data", (chunk) => output += chunk);
  shell.stderr.on("data", (chunk) => output += chunk);
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(3000);
    const show = spawnSync("qs", [
      "-p",
      shellQml,
      "ipc",
      "--pid",
      String(shell.pid),
      "show",
    ], {
      encoding: "utf8",
      timeout: 5000,
      env,
    });
    const call = spawnSync(
      "qs",
      [
        "-p",
        shellQml,
        "ipc",
        "--pid",
        String(shell.pid),
        "call",
        "lock",
        "lock",
      ],
      { encoding: "utf8", timeout: 5000, env },
    );
    await exited;
    assert.match(show.stdout, /target notifs/, show.stdout + show.stderr);
    assert.doesNotMatch(show.stdout, /target lock/, show.stdout);
    assert.match(call.stdout + call.stderr, /Target not found/);
    assert.doesNotMatch(output, /WlSessionLock|session lock/i, output);
  } finally {
    clearTimeout(stop);
    shell.kill();
  }
});
