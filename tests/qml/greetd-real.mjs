import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:net";
import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { endianness, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// The real greeter entrypoint, pointed at a private fake greetd socket. The
// fake server never executes the requested session command.
async function runGreeter(failure, credentials) {
  const dir = mkdtempSync(join(tmpdir(), "notch-real-"));
  const path = join(dir, "socket");
  const requests = [];
  const server = createServer((connection) => {
    let buffer = Buffer.alloc(0);
    connection.on("error", (error) => {
      if (error.code !== "ECONNRESET") throw error;
    });
    function reply(payload) {
      const json = Buffer.from(JSON.stringify(payload));
      const length = Buffer.alloc(4);
      if (endianness() === "LE") length.writeUInt32LE(json.length);
      else length.writeUInt32BE(json.length);
      connection.write(Buffer.concat([length, json]));
    }
    connection.on("data", (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      while (buffer.length >= 4) {
        const length = endianness() === "LE"
          ? buffer.readUInt32LE()
          : buffer.readUInt32BE();
        if (buffer.length < length + 4) break;
        const request = JSON.parse(buffer.subarray(4, length + 4).toString());
        buffer = buffer.subarray(length + 4);
        requests.push({ ...request, time: Date.now() });
        if (requests.length === 1) {
          reply({
            type: "auth_message",
            auth_message_type: "secret",
            auth_message: "Password:",
          });
        } else if (requests.length === 2) {
          reply(
            failure
              ? {
                type: "error",
                error_type: "auth_error",
                description: "Authentication failure",
              }
              : { type: "success" },
          );
        } else if (request.type === "cancel_session") {
          reply({ type: "success" });
        } else {
          reply({ type: "success" });
        }
      }
    });
  });
  await new Promise((resolve, reject) =>
    server.listen(path, resolve).once("error", reject)
  );
  try {
    const child = spawn("qs", [
      "-p",
      fileURLToPath(new URL("../../greetd-shell.qml", import.meta.url)),
    ], {
      env: {
        ...process.env,
        GREETD_SOCK: path,
        NOTCH_GREETD_AUTOTEST: "1",
        NOTCH_GREETD_TEST_FAILURE: failure ? "1" : "0",
        NOTCH_GREETD_TEST_SESSION: "mock-session-not-executed",
        ...(credentials
          ? {
            NOTCH_GREETD_TEST_USER: credentials.user,
            NOTCH_GREETD_TEST_SECRET: credentials.secret,
          }
          : {}),
        QT_QPA_PLATFORM: "offscreen",
        QT_QUICK_BACKEND: "software",
      },
      stdio: ["ignore", "pipe", "pipe"],
    });
    let output = "";
    child.stdout.on("data", (chunk) => output += chunk);
    child.stderr.on("data", (chunk) => output += chunk);
    const code = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        child.kill();
        reject(new Error("greeter timed out: " + output));
      }, 15000);
      child.once("error", (error) => {
        clearTimeout(timer);
        reject(error);
      });
      child.once("exit", (status) => {
        clearTimeout(timer);
        resolve(status);
      });
    });
    return { code, output, requests };
  } finally {
    await new Promise((resolve) => server.close(resolve));
    rmSync(dir, { recursive: true, force: true });
  }
}

test("the real greeter authenticates, compresses, then launches the session", async () => {
  const { code, output, requests } = await runGreeter(false);
  assert.equal(code, 0, output);
  assert.match(output, /real greeter launch passed/);
  assert.deepEqual(requests.map((r) => r.type), [
    "create_session",
    "post_auth_message_response",
    "start_session",
  ]);
  assert.equal(requests[0].username, "preview-user");
  assert.equal(requests[1].response, "fake-test-secret");
  assert.deepEqual(requests[2].cmd, ["mock-session-not-executed"]);
  assert.ok(
    requests[2].time - requests[1].time >= 450,
    "the session must wait for the compression",
  );
});

test("the real greeter expands with the error and never launches on failure", async () => {
  const { code, output, requests } = await runGreeter(true);
  assert.equal(code, 0, output);
  assert.match(output, /real greeter failure passed/);
  assert.deepEqual(requests.map((r) => r.type), [
    "create_session",
    "post_auth_message_response",
    "cancel_session",
  ]);
  assert.equal(requests[0].username, "preview-failure");
});

test("the autotest credentials can come from the environment", async () => {
  const { code, output, requests } = await runGreeter(false, {
    user: "throwaway-user",
    secret: "throwaway-secret",
  });
  assert.equal(code, 0, output);
  assert.match(output, /real greeter launch passed/);
  assert.equal(requests[0].username, "throwaway-user");
  assert.equal(requests[1].response, "throwaway-secret");
});
