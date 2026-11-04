import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./caffeine-ipc.qml", import.meta.url));
const env = Object.assign({}, process.env, {
  NOTCH_SMOKE: "0",
  QT_QPA_PLATFORM: "wayland",
  NO_COLOR: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
  NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const ipc = (fn) =>
  spawnSync("qs", ["-p", probe, "ipc", "call", "caffeine", fn], {
    encoding: "utf8",
    timeout: 5000,
    env,
  });

test("caffeine starts off and the IPC toggle turns it on and off", async () => {
  const shell = spawn("qs", ["-p", probe], { env });
  let output = "";
  shell.stdout.on("data", (chunk) => output += chunk);
  shell.stderr.on("data", (chunk) => output += chunk);
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(2000);
    const first = ipc("toggle");
    await sleep(500);
    const second = ipc("toggle");
    await exited;
    assert.equal(first.status, 0, first.stdout + first.stderr);
    assert.equal(second.status, 0, second.stdout + second.stderr);
    const states = output.match(/caffeine: (true|false)/g);
    assert.deepEqual(states, [
      "caffeine: false",
      "caffeine: true",
      "caffeine: false",
    ]);
  } finally {
    shell.kill();
  }
});
