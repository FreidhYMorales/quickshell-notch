import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./lock-ipc.qml", import.meta.url));
const env = Object.assign({}, process.env, {
  NOTCH_SMOKE: "0",
  QT_QPA_PLATFORM: "wayland",
  NO_COLOR: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
  NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test("the lock IPC target requests the lock once per call", async () => {
  const shell = spawn("qs", ["-p", probe], { env });
  let output = "";
  shell.stdout.on("data", (chunk) => output += chunk);
  shell.stderr.on("data", (chunk) => output += chunk);
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(2000);
    const call = spawnSync("qs", ["-p", probe, "ipc", "call", "lock", "lock"], {
      encoding: "utf8",
      timeout: 5000,
      env,
    });
    await exited;
    assert.equal(call.status, 0, call.stdout + call.stderr);
    assert.deepEqual(
      output.match(/lock: requested/g),
      ["lock: requested"],
      output,
    );
  } finally {
    shell.kill();
  }
});
