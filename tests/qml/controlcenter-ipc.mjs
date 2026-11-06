import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(
  new URL("./controlcenter-ipc.qml", import.meta.url),
);
const env = Object.assign({}, process.env, {
  NOTCH_SMOKE: "0",
  QT_QPA_PLATFORM: "wayland",
  NO_COLOR: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
  NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const ipc = (fn) =>
  spawnSync("qs", ["-p", probe, "ipc", "call", "controlcenter", fn], {
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

test("controlcenter opens the root and notifications views on the focused monitor", async () => {
  const monitor = focusedMonitor();
  const shell = spawn("qs", ["-p", probe], { env });
  let output = "";
  shell.stdout.on("data", (chunk) => (output += chunk));
  shell.stderr.on("data", (chunk) => (output += chunk));
  const exited = new Promise((resolve) => shell.on("exit", resolve));
  try {
    await sleep(2000);
    const notifications = ipc("notifications");
    await sleep(500);
    const root = ipc("open");
    await sleep(500);
    shell.kill();
    await exited;
    assert.equal(
      notifications.status,
      0,
      notifications.stdout + notifications.stderr,
    );
    assert.equal(root.status, 0, root.stdout + root.stderr);
    const lines = output.match(/controlcenter: (root|notifications) \S+/g);
    assert.deepEqual(lines, [
      `controlcenter: notifications ${monitor}`,
      `controlcenter: root ${monitor}`,
    ]);
  } finally {
    shell.kill();
  }
});
