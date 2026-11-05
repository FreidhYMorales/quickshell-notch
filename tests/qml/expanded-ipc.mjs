import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./expanded-ipc.qml", import.meta.url));
const env = Object.assign({}, process.env, {
  NOTCH_SMOKE: "0",
  QT_QPA_PLATFORM: "wayland",
  NO_COLOR: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
  NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const ipc = (fn) =>
  spawnSync("qs", ["-p", probe, "ipc", "call", "expanded", fn], {
    encoding: "utf8",
    timeout: 5000,
    env,
  });

// The expected monitor comes from the compositor, not from the code under test.
function focusedMonitor() {
  const result = spawnSync("hyprctl", ["monitors", "-j"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  const focused = JSON.parse(result.stdout).find((monitor) => monitor.focused);
  assert.ok(focused, "the compositor reports no focused monitor");
  return focused.name;
}

test("expanded toggle asks the focused monitor", async () => {
  const monitor = focusedMonitor();
  const shell = spawn("qs", ["-p", probe], { env });
  let output = "";
  shell.stdout.on("data", (chunk) => (output += chunk));
  shell.stderr.on("data", (chunk) => (output += chunk));
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(2000);
    const toggle = ipc("toggle");
    await sleep(500);
    shell.kill();
    await exited;
    assert.equal(toggle.status, 0, toggle.stdout + toggle.stderr);
    const lines = output.match(/expanded: \S+/g);
    assert.deepEqual(lines, [`expanded: ${monitor}`]);
  } finally {
    shell.kill();
  }
});
