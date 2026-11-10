#!/usr/bin/env node
// Real PAM test for the greetd greeter, isolated from the running session.
//
// It starts a second greetd with a temporary config on `vt = "none"`: no VT is
// opened, no keyboard or compositor is touched, and no display manager is
// changed. Authentication runs against a throwaway account whose random
// password only lives in this process memory. greetd and the account are
// removed on exit, including on failure.
//
// Run as root: sudo node scripts/test-greetd-pam.mjs
import { spawn, spawnSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { connect } from "node:net";
import { endianness, tmpdir } from "node:os";
import { join } from "node:path";

const GREETER = "greeter";
const TIMEOUT = 30000;

function fail(message) {
  throw new Error(message);
}

function run(command, args, input) {
  const result = spawnSync(command, args, {
    input,
    encoding: "utf8",
    stdio: [input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
  });
  if (result.error) fail(`${command} failed: ${result.error.message}`);
  if (result.status !== 0) {
    fail(
      `${command} ${args.join(" ")} failed (${result.status}): ` +
        (result.stderr || result.stdout).trim(),
    );
  }
  return result.stdout;
}

function encode(message) {
  const json = Buffer.from(JSON.stringify(message));
  const length = Buffer.alloc(4);
  if (endianness() === "LE") length.writeUInt32LE(json.length);
  else length.writeUInt32BE(json.length);
  return Buffer.concat([length, json]);
}

function withTimeout(promise, what) {
  let timer = null;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`timed out waiting for ${what}`)),
      TIMEOUT,
    );
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

// One connection, one session. greetd sends length-prefixed JSON frames with
// the host byte order, the same protocol the greeter uses.
function connectTo(path) {
  return new Promise((resolve, reject) => {
    const socket = connect(path);
    let buffer = Buffer.alloc(0);
    let waiting = null;
    let opened = false;
    const queued = [];

    function settle(error) {
      if (!waiting) return;
      const pending = waiting;
      waiting = null;
      if (error) pending.reject(error);
    }

    socket.on("data", (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      while (buffer.length >= 4) {
        const length = endianness() === "LE"
          ? buffer.readUInt32LE(0)
          : buffer.readUInt32BE(0);
        if (buffer.length < length + 4) break;
        const message = JSON.parse(buffer.subarray(4, length + 4).toString());
        buffer = buffer.subarray(length + 4);
        if (waiting) {
          const pending = waiting;
          waiting = null;
          pending.resolve(message);
        } else {
          queued.push(message);
        }
      }
    });
    socket.on("error", (error) => {
      if (!opened) reject(error);
      settle(error);
    });
    socket.on("close", () => {
      if (!opened) reject(new Error("greetd closed the connection"));
      settle(new Error("greetd closed the connection"));
    });
    socket.once("connect", () => {
      opened = true;
      resolve({
        send: (message) => socket.write(encode(message)),
        next: () =>
          queued.length > 0
            ? Promise.resolve(queued.shift())
            : new Promise((resolveNext, rejectNext) => {
              waiting = { resolve: resolveNext, reject: rejectNext };
            }),
        close: () => socket.destroy(),
      });
    });
  });
}

// Never logs the password. Returns "success" or the greetd error type.
async function attempt(path, user, password, launch) {
  const client = await connectTo(path);
  try {
    client.send({ type: "create_session", username: user });
    for (;;) {
      const message = await withTimeout(client.next(), "an auth response");
      if (message.type === "auth_message") {
        const kind = message.auth_message_type;
        // Only these two kinds expect an answer; info/error messages do not.
        if (kind === "secret" || kind === "visible") {
          client.send({
            type: "post_auth_message_response",
            response: password,
          });
        }
        continue;
      }
      if (message.type === "error") {
        // greetd keeps the failed session in `configuring` until the client
        // cancels it; closing the socket is not enough. This is the retry the
        // greeter performs after a wrong password. The session worker usually
        // exits before the cancel arrives, so greetd answers with a
        // connection error even though it already released the session.
        client.send({ type: "cancel_session" });
        const cancelled = await withTimeout(
          client.next(),
          "the cancel_session reply",
        );
        if (
          cancelled.type !== "success" &&
          !/Connection refused/.test(cancelled.description || "")
        ) {
          fail(`cancel_session failed: ${JSON.stringify(cancelled)}`);
        }
        return {
          result: message.error_type || "error",
          description: message.description || "",
        };
      }
      if (message.type !== "success") {
        fail(`unexpected greetd message: ${JSON.stringify(message)}`);
      }
      break;
    }
    if (!launch) return { result: "success", description: "" };
    // The session command runs as the throwaway user without a VT. `true`
    // proves the launch path without keeping a process around.
    client.send({ type: "start_session", cmd: ["/usr/bin/true"], env: [] });
    const reply = await withTimeout(client.next(), "the start_session reply");
    if (reply.type !== "success") {
      fail(`start_session failed: ${JSON.stringify(reply)}`);
    }
    // Give the tiny session a moment to actually run before cleanup.
    spawnSync("sleep", ["0.3"]);
    return { result: "success", description: "" };
  } finally {
    client.close();
  }
}

function waitForSocket(child, candidates) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    for (const candidate of candidates) {
      if (existsSync(candidate)) return candidate;
    }
    if (child.exitCode !== null) {
      fail(`greetd exited with ${child.exitCode} before creating its socket`);
    }
    spawnSync("sleep", ["0.1"]);
  }
  fail("greetd did not create its socket in 10 s");
}

async function main() {
  if (process.geteuid() !== 0) {
    console.error(
      "run this test as root: sudo node scripts/test-greetd-pam.mjs",
    );
    process.exit(2);
  }
  run("id", ["-u", GREETER]);

  const dir = join(
    tmpdir(),
    `notch-greetd-pam-${randomBytes(4).toString("hex")}`,
  );
  mkdirSync(dir, { mode: 0o711 });
  const user = `notch-pam-${randomBytes(4).toString("hex")}`;
  // base64url has no `:` or whitespace, so chpasswd cannot split it.
  const password = randomBytes(18).toString("base64url");
  const configPath = join(dir, "config.toml");
  const runfile = join(dir, "runfile");
  writeFileSync(
    configPath,
    [
      "[terminal]",
      "# No VT at all: the test never opens a terminal or grabs a keyboard.",
      'vt = "none"',
      "",
      "[general]",
      `runfile = "${runfile}"`,
      "",
      "[default_session]",
      'command = "/bin/sleep 600"',
      `user = "${GREETER}"`,
      "",
    ].join("\n"),
  );

  let child = null;
  const log = [];
  try {
    run("useradd", [
      "-M",
      "-d",
      "/nonexistent",
      "-s",
      "/bin/sh",
      "-c",
      "Notch PAM test",
      user,
    ]);
    run("chpasswd", [], `${user}:${password}\n`);
    console.log(`account: ${user} (deleted on exit)`);

    child = spawn(
      "/usr/bin/greetd",
      ["-c", configPath, "-s", join(dir, "socket")],
      { detached: true, stdio: ["ignore", "pipe", "pipe"] },
    );
    child.stdout.on("data", (chunk) => log.push(chunk.toString()));
    child.stderr.on("data", (chunk) => log.push(chunk.toString()));
    // Arch's build names the socket after its pid; other builds honour -s.
    const socket = waitForSocket(child, [
      join(dir, "socket"),
      `/run/greetd-${child.pid}.sock`,
    ]);
    console.log(`greetd: pid ${child.pid}, socket ${socket}`);

    console.log("1/2 wrong password is rejected by PAM");
    const wrong = await attempt(socket, user, `${password}-wrong`, false);
    if (wrong.result !== "auth_error" || wrong.description === "") {
      fail(`expected an auth_error, got ${JSON.stringify(wrong)}`);
    }
    console.log(`   rejected: ${wrong.description}`);

    console.log("2/2 right password authenticates and launches the session");
    const launched = await attempt(socket, user, password, true);
    if (launched.result !== "success") {
      fail(`expected a launch, got ${JSON.stringify(launched)}`);
    }
    console.log("PASS: real greetd + PAM authentication works");
  } catch (error) {
    console.error(`FAIL: ${error.message}`);
    if (log.length > 0) console.error(log.join("").trim());
    process.exitCode = 1;
  } finally {
    if (child) {
      try {
        process.kill(-child.pid, "SIGTERM");
      } catch (_e) {
        try {
          child.kill("SIGTERM");
        } catch (_ignored) {
          // already gone
        }
      }
      spawnSync("sleep", ["0.5"]);
      try {
        process.kill(-child.pid, "SIGKILL");
      } catch (_e) {
        // already gone
      }
      for (
        const path of [join(dir, "socket"), `/run/greetd-${child.pid}.sock`]
      ) {
        rmSync(path, { force: true });
      }
    }
    // Reset faillock before removing the account, or /run keeps its entry.
    spawnSync("faillock", ["--user", user, "--reset"], { stdio: "ignore" });
    spawnSync("userdel", ["-r", user], { stdio: "ignore" });
    rmSync(`/var/spool/mail/${user}`, { force: true });
    rmSync(runfile, { force: true });
    rmSync(dir, { recursive: true, force: true });
  }
}

main().then(
  () => process.exit(process.exitCode ?? 0),
  (error) => {
    console.error(`FAIL: ${error.stack || error.message}`);
    process.exit(1);
  },
);
