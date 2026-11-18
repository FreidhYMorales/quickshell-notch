import { spawn, spawnSync } from "node:child_process";
import { lstatSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const runtime = mkdtempSync(join(tmpdir(), "notch-lock-isolated-"));
const initialRuntimeInfo = lstatSync(runtime);
const server = join(runtime, "server");
const source = fileURLToPath(new URL("./lock-compositor.c", import.meta.url));
const probe = fileURLToPath(new URL("./lock-protocol.qml", import.meta.url));
const flags = spawnSync("pkg-config", [
  "--cflags",
  "--libs",
  "wlroots-0.20",
  "wayland-server",
], { encoding: "utf8" });
if (flags.status !== 0) {
  throw new Error("Install wlroots 0.20 development headers and pkg-config");
}
const runtimeInfo = lstatSync(runtime);
if (
  !runtimeInfo.isDirectory() || runtimeInfo.uid !== process.getuid() ||
  (runtimeInfo.mode & 0o7777) !== 0o700 ||
  runtimeInfo.dev !== initialRuntimeInfo.dev ||
  runtimeInfo.ino !== initialRuntimeInfo.ino
) {
  throw new Error("Unsafe isolated runtime directory");
}
const compiled = spawnSync("cc", [
  "-Wall",
  "-Wextra",
  "-Werror",
  "-DWLR_USE_UNSTABLE",
  source,
  "-o",
  server,
  ...flags.stdout.trim().split(/\s+/),
], { encoding: "utf8" });
if (compiled.status !== 0) throw new Error(compiled.stderr);
const env = {
  PATH: process.env.PATH,
  HOME: runtime,
  XDG_RUNTIME_DIR: runtime,
  WAYLAND_DISPLAY: "notch-test",
  HYPRLAND_INSTANCE_SIGNATURE: "",
  QT_QPA_PLATFORM: "wayland",
  QT_QUICK_BACKEND: "software",
  NOTCH_SMOKE: "1",
  QS_DISABLE_CRASH_HANDLER: "1",
};
const compositor = spawn(server, { env });
try {
  await new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error("isolated compositor did not start")),
      5000,
    );
    compositor.stdout.on("data", (chunk) => {
      if (String(chunk).includes("isolated: ready")) {
        clearTimeout(timer);
        resolve();
      }
    });
    compositor.once(
      "exit",
      (code) => reject(new Error(`compositor exited: ${code}`)),
    );
    compositor.once("error", reject);
  });
  const socketInfo = lstatSync(join(runtime, env.WAYLAND_DISPLAY), {
    throwIfNoEntry: false,
  });
  if (
    !socketInfo || !socketInfo.isSocket() || socketInfo.uid !== process.getuid()
  ) {
    throw new Error("Unsafe isolated socket");
  }
  const result = spawnSync("qs", ["-p", probe], {
    env,
    encoding: "utf8",
    timeout: 8000,
  });
  if (
    result.status !== 0 ||
    !(result.stdout + result.stderr).includes("isolated: secure")
  ) {
    throw new Error(
      "isolated session lock failed:\n" + result.stdout + result.stderr,
    );
  }
  console.log("isolated: secure lock and unlock passed");
} finally {
  compositor.kill("SIGTERM");
  if (compositor.exitCode === null && compositor.signalCode === null) {
    await new Promise((resolve) => compositor.once("exit", resolve));
  }
  rmSync(runtime, { recursive: true, force: true });
}
