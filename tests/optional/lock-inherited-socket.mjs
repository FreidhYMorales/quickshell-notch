import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { createServer } from "node:net";
import { spawn } from "node:child_process";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

test("the isolated runner never connects to an inherited Wayland socket", async () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-socket-sentinel-"));
  const sentinel = createServer();
  await new Promise((resolve) => sentinel.listen(join(dir, "socket"), resolve));
  const fd = sentinel._handle.fd;
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    const child = spawn(process.execPath, [runner], {
      env: { ...process.env, WAYLAND_SOCKET: "3" },
      stdio: ["ignore", "pipe", "pipe", fd],
    });
    let log = "";
    child.stdout.on("data", (chunk) => log += chunk);
    child.stderr.on("data", (chunk) => log += chunk);
    const code = await new Promise((resolve, reject) => {
      child.once("error", reject);
      child.once("exit", resolve);
    });
    assert.equal(code, 0, log);
    assert.match(log, /isolated: secure lock and unlock passed/);
  } finally {
    await new Promise((resolve) => sentinel.close(resolve));
    rmSync(dir, { recursive: true, force: true });
  }
});
