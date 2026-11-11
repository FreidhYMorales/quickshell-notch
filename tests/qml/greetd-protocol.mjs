import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:net";
import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { endianness, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { loginMorph } from "../../shell/config/motion.mjs";

test("visual adapter refuses an unapproved socket without connecting", async () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-disallowed-"));
  const path = join(dir, "socket");
  let connections = 0;
  const server = createServer((socket) => {
    connections++;
    socket.destroy();
  });
  await new Promise((resolve, reject) =>
    server.listen(path, resolve).once("error", reject)
  );
  try {
    const child = spawn("qs", [
      "-p",
      fileURLToPath(new URL("../../greetd-preview-shell.qml", import.meta.url)),
    ], {
      env: {
        ...process.env,
        GREETD_SOCK: path,
        NOTCH_GREETD_MOCK: "1",
        QT_QPA_PLATFORM: "offscreen",
        QT_QUICK_BACKEND: "software",
      },
      stdio: "ignore",
    });
    const code = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        child.kill();
        reject(new Error("guard timed out"));
      }, 10000);
      child.once("error", (error) => {
        clearTimeout(timer);
        reject(error);
      });
      child.once("exit", (status) => {
        clearTimeout(timer);
        resolve(status);
      });
    });
    assert.equal(code, 2);
    assert.equal(connections, 0);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    rmSync(dir, { recursive: true, force: true });
  }
});

for (const visual of [false, true]) {
  for (const failure of [false, true]) {
    test(
      failure
        ? `${
          visual ? "Visual adapter" : "Quickshell"
        } handles final greetd failure without launching`
        : `${
          visual ? "Visual adapter" : "Quickshell"
        } distinguishes greetd messages and launches only after animation`,
      async () => {
        const dir = mkdtempSync(join(tmpdir(), "notch-greetd-"));
        const path = join(dir, "socket");
        const requests = [];
        const server = createServer((connection) => {
          let buffer = Buffer.alloc(0);
          connection.on("error", (error) => {
            // The child may exit while the mock server acknowledges cancellation.
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
              const request = JSON.parse(
                buffer.subarray(4, length + 4).toString(),
              );
              buffer = buffer.subarray(length + 4);
              requests.push({ ...request, time: Date.now() });
              const n = requests.length;
              if (n === 1) {
                reply({
                  type: "auth_message",
                  auth_message_type: "info",
                  auth_message: "Testing",
                });
              } else if (n === 2) {
                reply({
                  type: "auth_message",
                  auth_message_type: "error",
                  auth_message: "Recoverable notice",
                });
              } else if (n === 3) {
                reply({
                  type: "auth_message",
                  auth_message_type: "secret",
                  auth_message: "Dummy password:",
                });
              } else if (n === 4 && failure) {
                reply({
                  type: "error",
                  error_type: "auth_error",
                  description: "Authentication failed",
                });
              } else reply({ type: "success" });
            }
          });
        });
        await new Promise((resolve, reject) =>
          server.listen(path, resolve).once("error", reject)
        );
        try {
          const child = spawn("qs", [
            "-p",
            fileURLToPath(
              new URL(
                visual
                  ? "../../greetd-preview-shell.qml"
                  : "./greetd-protocol-probe.qml",
                import.meta.url,
              ),
            ),
          ], {
            env: {
              ...process.env,
              GREETD_SOCK: path,
              NOTCH_GREETD_TEST_FAILURE: failure ? "1" : "0",
              NOTCH_GREETD_MOCK: "1",
              NOTCH_GREETD_AUTOTEST: visual ? "1" : "0",
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
              reject(new Error("probe timed out: " + output));
            }, 10000);
            child.once("error", (error) => {
              clearTimeout(timer);
              reject(error);
            });
            child.once("exit", (status) => {
              clearTimeout(timer);
              resolve(status);
            });
          });
          assert.equal(code, 0, output);
          assert.match(
            output,
            visual
              ? (failure
                ? /visual greetd failure passed/
                : /visual greetd success passed/)
              : (failure
                ? /greetd final failure probe passed/
                : /greetd protocol probe passed/),
          );
          const expected = [
            "create_session",
            "post_auth_message_response",
            "post_auth_message_response",
            "post_auth_message_response",
          ];
          expected.push(failure ? "cancel_session" : "start_session");
          assert.deepEqual(requests.map((r) => r.type), expected);
          assert.equal(requests[3].response, "fake-test-secret");
          if (!failure) {
            assert.deepEqual(requests[4].cmd, ["mock-session-not-executed"]);
            assert.ok(
              requests[4].time - requests[3].time >= loginMorph - 50,
              "launch must wait for simulated animation",
            );
          }
        } finally {
          await new Promise((resolve) => server.close(resolve));
          rmSync(dir, { recursive: true, force: true });
        }
      },
    );
  }
}

test("visual adapter retries after a wrong password and still launches", async () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-greetd-"));
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
            auth_message_type: "info",
            auth_message: "Simulated login",
          });
        } else if (requests.length === 2) {
          reply({
            type: "auth_message",
            auth_message_type: "secret",
            auth_message: "Dummy password:",
          });
        } else if (requests.length === 3) {
          reply({
            type: "error",
            error_type: "auth_error",
            description: "Incorrect password",
          });
        } else if (requests.length === 4) {
          reply({ type: "success" });
        } else if (requests.length === 5) {
          reply({
            type: "auth_message",
            auth_message_type: "info",
            auth_message: "Simulated login",
          });
        } else if (requests.length === 6) {
          reply({
            type: "auth_message",
            auth_message_type: "secret",
            auth_message: "Dummy password:",
          });
        } else reply({ type: "success" });
      }
    });
  });
  await new Promise((resolve, reject) =>
    server.listen(path, resolve).once("error", reject)
  );
  try {
    const child = spawn("qs", [
      "-p",
      fileURLToPath(
        new URL("../../greetd-preview-shell.qml", import.meta.url),
      ),
    ], {
      env: {
        ...process.env,
        GREETD_SOCK: path,
        NOTCH_GREETD_MOCK: "1",
        NOTCH_GREETD_AUTOTEST: "1",
        NOTCH_GREETD_RETRY: "1",
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
        reject(new Error("probe timed out: " + output));
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
    assert.equal(code, 0, output);
    assert.match(output, /visual greetd retry passed/);
    assert.deepEqual(requests.map((r) => r.type), [
      "create_session",
      "post_auth_message_response",
      "post_auth_message_response",
      "cancel_session",
      "create_session",
      "post_auth_message_response",
      "post_auth_message_response",
      "start_session",
    ]);
    assert.equal(requests[2].response, "fake-test-secret");
    assert.equal(requests[6].response, "fake-test-secret");
    assert.deepEqual(requests[7].cmd, ["mock-session-not-executed"]);
    assert.ok(
      requests[7].time - requests[6].time >= loginMorph - 50,
      "the retry must animate before launching",
    );
  } finally {
    await new Promise((resolve) => server.close(resolve));
    rmSync(dir, { recursive: true, force: true });
  }
});
