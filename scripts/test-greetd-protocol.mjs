#!/usr/bin/env node
// Private fake greetd socket: no PAM, real credentials, or session execution.
import { createServer } from "node:net";
import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { endianness } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { readPreviewSettings } from "./greetd-preview-settings.mjs";

const dir = mkdtempSync("/tmp/notch-greetd-");
const socket = join(dir, "socket");
const root = fileURLToPath(new URL("..", import.meta.url));
const state = process.env.XDG_STATE_HOME ||
  join(process.env.HOME, ".local/state");
const { background, theme } = readPreviewSettings(state);

const server = createServer((connection) => {
  let buffer = Buffer.alloc(0);
  connection.on("error", (error) => {
    if (error.code !== "ECONNRESET") throw error;
  });
  let phase = "idle";
  let fail = false;
  function reply(payload) {
    const data = Buffer.from(JSON.stringify(payload));
    const header = Buffer.alloc(4);
    if (endianness() === "LE") header.writeUInt32LE(data.length);
    else header.writeUInt32BE(data.length);
    connection.write(Buffer.concat([header, data]));
  }
  connection.on("data", (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    while (buffer.length >= 4) {
      const size = endianness() === "LE"
        ? buffer.readUInt32LE()
        : buffer.readUInt32BE();
      if (size > 65536) return connection.destroy();
      if (buffer.length < size + 4) return;
      let request;
      try {
        request = JSON.parse(buffer.subarray(4, size + 4));
      } catch (_error) {
        return connection.destroy();
      }
      buffer = buffer.subarray(size + 4);
      if (
        request.type === "create_session" && phase === "idle" &&
        ["preview-user", "preview-failure"].includes(request.username)
      ) {
        fail = request.username === "preview-failure";
        phase = "info";
        reply({
          type: "auth_message",
          auth_message_type: "info",
          auth_message: "Simulated login",
        });
      } else if (
        request.type === "post_auth_message_response" && phase === "info"
      ) {
        phase = "secret";
        reply({
          type: "auth_message",
          auth_message_type: "secret",
          auth_message: "Dummy password:",
        });
      } else if (
        request.type === "post_auth_message_response" && phase === "secret" &&
        request.response === "fake-test-secret"
      ) {
        phase = fail ? "failed" : "ready";
        reply(
          fail
            ? {
              type: "error",
              error_type: "auth_error",
              description: "Simulated failure",
            }
            : { type: "success" },
        );
      } else if (request.type === "cancel_session" && phase === "failed") {
        phase = "idle";
        reply({ type: "success" });
      } else if (
        request.type === "start_session" && phase === "ready" &&
        JSON.stringify(request.cmd) ===
          JSON.stringify(["mock-session-not-executed"])
      ) {
        phase = "launched";
        reply({ type: "success" }); // Acknowledgement only: never execute request.cmd.
      } else {
        connection.destroy();
        return;
      }
    }
  });
});

await new Promise((resolve, reject) =>
  server.listen(socket, resolve).once("error", reject)
);
try {
  const child = spawn("qs", ["-p", join(root, "greetd-preview-shell.qml")], {
    env: {
      ...process.env,
      GREETD_SOCK: socket,
      NOTCH_GREETD_MOCK: "1",
      NOTCH_GREETD_AUTOTEST: process.env.NOTCH_GREETD_AUTOTEST === "1"
        ? "1"
        : "0",
      NOTCH_GREETD_PREVIEW_BG: background,
      NOTCH_GREETD_PREVIEW_ACCENT: theme.accent,
      NOTCH_GREETD_PREVIEW_FOREGROUND: theme.foreground,
      NOTCH_GREETD_PREVIEW_WIDTH: String(theme.notchWidth),
    },
    stdio: "inherit",
  });
  const code = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("exit", (status) => resolve(status));
  });
  if (code !== 0) process.exitCode = code || 1;
} finally {
  await new Promise((resolve) => server.close(resolve));
  rmSync(dir, { recursive: true, force: true });
}
