import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:net";
import { spawn, spawnSync } from "node:child_process";
import {
  copyFileSync,
  mkdirSync,
  mkdtempSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { endianness, tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// The real greeter entrypoint, pointed at a private fake greetd socket. The
// fake server never executes the requested session command. A deployment can
// be checked by pointing NOTCH_GREETD_ENTRYPOINT at its installed copy.
const defaultEntrypoint = process.env.NOTCH_GREETD_ENTRYPOINT ||
  fileURLToPath(new URL("../../greetd-shell.qml", import.meta.url));

async function runGreeter(
  failure,
  credentials,
  visualDir,
  nested = false,
  fullScreen = false,
  entrypoint = defaultEntrypoint,
) {
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
    const program = nested ? "cage" : "qs";
    const args = [
      "-p",
      entrypoint,
    ];
    const child = spawn(program, nested ? ["--", "qs", ...args] : args, {
      env: {
        ...process.env,
        GREETD_SOCK: path,
        NOTCH_GREETD_AUTOTEST: "1",
        NOTCH_GREETD_TEST_FAILURE: failure ? "1" : "0",
        NOTCH_GREETD_TEST_GEOMETRY_DELAY: fullScreen ? "3000" : "500",
        NOTCH_GREETD_TEST_SESSION: "mock-session-not-executed",
        NOTCH_GREETD_VISUAL_DIR: visualDir || "",
        NOTCH_GREETD_TEST_VISUAL: visualDir ? "1" : "0",
        ...(credentials
          ? {
            NOTCH_GREETD_TEST_USER: credentials.user,
            NOTCH_GREETD_TEST_SECRET: credentials.secret,
          }
          : {}),
        QT_QPA_PLATFORM: nested ? "wayland" : "offscreen",
        QT_QUICK_BACKEND: "software",
        ...(nested
          ? {
            WLR_BACKENDS: "wayland",
            WLR_RENDERER: "pixman",
            NOTCH_GREETD_TEST_GEOMETRY: "1",
          }
          : {}),
      },
      stdio: ["ignore", "pipe", "pipe"],
    });
    let output = "";
    child.stdout.on("data", (chunk) => output += chunk);
    child.stderr.on("data", (chunk) => output += chunk);
    let outerGeometry = null;
    if (fullScreen) {
      try {
        outerGeometry = await targetNestedCage(child.pid);
      } catch (error) {
        child.kill("SIGTERM");
        if (child.exitCode === null && child.signalCode === null) {
          await new Promise((resolve) => child.once("close", resolve));
        }
        throw error;
      }
    }
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
    return { code, output, requests, outerGeometry };
  } finally {
    await new Promise((resolve) => server.close(resolve));
    rmSync(dir, { recursive: true, force: true });
  }
}

async function targetNestedCage(pid) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    const result = spawnSync("hyprctl", ["-j", "clients"], {
      encoding: "utf8",
    });
    if (result.status !== 0) throw new Error("cannot inspect Hyprland windows");
    const clients = JSON.parse(result.stdout);
    const cage = clients.find((client) => client.pid === pid && client.mapped);
    if (cage) {
      if (!/^0x[0-9a-f]+$/i.test(cage.address)) {
        throw new Error("invalid Cage window address");
      }
      const expression =
        `hl.dsp.window.fullscreen({mode = "fullscreen", action = "set", window = "address:${cage.address}"})`;
      const switched = spawnSync("hyprctl", ["dispatch", expression], {
        encoding: "utf8",
      });
      if (switched.status !== 0 || !/^ok\s*$/.test(switched.stdout)) {
        throw new Error(
          "could not fullscreen the Cage window: " + switched.stdout +
            switched.stderr,
        );
      }
      console.log(`Cage ${cage.address} requested fullscreen`);
      while (Date.now() < deadline) {
        const state = spawnSync("hyprctl", ["-j", "clients"], {
          encoding: "utf8",
        });
        const current = state.status === 0
          ? JSON.parse(state.stdout).find((client) =>
            client.pid === pid && client.address === cage.address
          )
          : null;
        if (
          current && current.fullscreen === 2 && current.size[0] > 0 &&
          current.size[1] > 0
        ) {
          const displays = spawnSync("hyprctl", ["-j", "monitors"], {
            encoding: "utf8",
          });
          const monitor = displays.status === 0
            ? JSON.parse(displays.stdout).find((display) =>
              display.id === current.monitor && !display.disabled
            )
            : null;
          if (!monitor) {
            throw new Error("cannot identify the fullscreen monitor");
          }
          const rotated = monitor.transform % 2 === 1;
          const expected = [
            rotated ? monitor.height : monitor.width,
            rotated ? monitor.width : monitor.height,
          ].map((value) => Math.round(value / monitor.scale));
          if (
            current.size.some((value, index) =>
              Math.abs(value - expected[index]) > 1
            )
          ) throw new Error("Cage fullscreen size does not match its monitor");
          console.log(
            `monitor ${monitor.name}: ${monitor.width}x${monitor.height} scale=${monitor.scale} logical≈${
              expected.join("x")
            }`,
          );
          return current.size;
        }
        await new Promise((resolve) => setTimeout(resolve, 40));
      }
      throw new Error("Cage did not enter fullscreen");
    }
    await new Promise((resolve) => setTimeout(resolve, 40));
  }
  throw new Error(
    "could not find the Cage window; no other window was modified",
  );
}

test("nested Cage reports the real greeter window and output geometry", {
  skip: process.env.NOTCH_GREETD_CAGE_TEST !== "1",
}, async () => {
  const { code, output, requests } = await runGreeter(false, null, null, true);
  assert.equal(code, 0, output);
  assert.match(output, /greeter geometry: window=\d+x\d+ output=\d+x\d+/);
  assert.match(output, /real greeter launch passed/);
  const geometry = output.match(
    /greeter geometry: window=(\d+)x(\d+) output=(\d+)x(\d+)/,
  );
  console.log(geometry[0]);
  assert.ok(Number(geometry[1]) > 0 && Number(geometry[2]) > 0);
  assert.deepEqual(
    geometry.slice(1, 3),
    geometry.slice(3, 5),
    "window must fill the nested output",
  );
  assert.notEqual(
    geometry[1] + "x" + geometry[2],
    "1280x720",
    "test must exercise a non-default output size",
  );
  assert.deepEqual(requests.map((r) => r.type), [
    "create_session",
    "post_auth_message_response",
    "start_session",
  ]);
  assert.deepEqual(requests[2].cmd, ["mock-session-not-executed"]);
});

test("fullscreen nested Cage fills the selected Hyprland monitor", {
  skip: process.env.NOTCH_GREETD_CAGE_FULLSCREEN !== "1",
}, async () => {
  const { code, output, outerGeometry } = await runGreeter(
    false,
    null,
    null,
    true,
    true,
  );
  assert.equal(code, 0, output);
  assert.match(output, /greeter geometry: window=\d+x\d+ output=\d+x\d+/);
  assert.match(output, /real greeter launch passed/);
  const geometry = output.match(
    /greeter geometry: window=(\d+)x(\d+) output=(\d+)x(\d+)/,
  );
  assert.deepEqual(geometry.slice(1, 3), geometry.slice(3, 5));
  assert.deepEqual(geometry.slice(3, 5).map(Number), outerGeometry);
  console.log(`fullscreen Cage: ${outerGeometry.join("x")} logical pixels`);
});

test("the real entrypoint loads explicit shared visual settings", async () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-greeter-visual-"));
  try {
    writeFileSync(
      join(dir, "theme.conf.user"),
      "[General]\naccent=#123456\nnormalNotchWidth=444\n",
    );
    writeFileSync(join(dir, "wallpaper.txt"), "/shared/example.png\n");
    const { code, output } = await runGreeter(false, null, dir);
    assert.equal(code, 0, output);
    assert.match(output, /real greeter launch passed/);
    assert.doesNotMatch(output, /TypeError|ReferenceError|cannot assign/i);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("the real entrypoint reads the atomic visual manifest", async () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-greeter-manifest-"));
  try {
    const name = `background-${"a".repeat(64)}.png`;
    writeFileSync(
      join(dir, "visual.json"),
      JSON.stringify({
        version: 1,
        background: name,
        accent: "#123456",
        foreground: "#abcdef",
      }),
    );
    writeFileSync(join(dir, "theme.conf.user"), "[General]\naccent=#ffffff\n");
    const { code, output } = await runGreeter(false, null, dir);
    assert.equal(code, 0, output);
    const value = JSON.parse(output.match(/greeter visual: (\{[^\n]+\})/)[1]);
    assert.equal(value.accent, "#123456");
    assert.equal(value.foreground, "#abcdef");
    assert.equal(value.background, `file://${dir}/${name}`);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("the real entrypoint loads a minimal deployable greeter tree", async () => {
  const source = fileURLToPath(new URL("../../", import.meta.url));
  const target = mkdtempSync(join(tmpdir(), "notch-greeter-tree-"));
  const files = [
    "greetd-shell.qml",
    "greetd/preview/Main.qml",
    "shell/logic/greetdPreview.mjs",
    "shell/logic/greetdVisual.mjs",
    "shell/logic/wallpaperState.mjs",
    "shell/logic/earGeometry.mjs",
    "shell/logic/users.mjs",
    "sddm/notch/icons/arrow-right.svg",
    "sddm/notch/icons/chevron-down.svg",
    "sddm/notch/icons/chevron-left.svg",
    "sddm/notch/icons/keyboard.svg",
    "sddm/notch/icons/power.svg",
    "sddm/notch/icons/rotate-ccw.svg",
    "sddm/notch/shaders/keyboard.frag.qsb",
  ];
  try {
    for (const file of files) {
      const destination = join(target, file);
      mkdirSync(dirname(destination), { recursive: true });
      copyFileSync(join(source, file), destination);
    }
    const { code, output } = await runGreeter(
      false,
      null,
      null,
      false,
      false,
      join(target, "greetd-shell.qml"),
    );
    assert.equal(code, 0, output);
    assert.match(output, /real greeter launch passed/);
    assert.doesNotMatch(
      output,
      /TypeError|ReferenceError|Failed to load|module .* is not installed/i,
    );
  } finally {
    rmSync(target, { recursive: true, force: true });
  }
});

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
