import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const lockSessions = fileURLToPath(
  new URL("../system/lock-sessions", import.meta.url),
);
const fakeQs = fileURLToPath(
  new URL("./fixtures/fake-qs.sh", import.meta.url),
);

// Runs the lock step with a fake `qs` first on the PATH; returns its ipc calls.
function runLockSessions(env) {
  const dir = mkdtempSync(join(tmpdir(), "notch-lock-sessions-"));
  try {
    copyFileSync(fakeQs, join(dir, "qs"));
    const log = join(dir, "calls.log");
    const started = Date.now();
    const result = spawnSync("bash", [lockSessions], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        PATH: dir + ":" + process.env.PATH,
        FAKE_QS_LOG: log,
      }, env),
    });
    const calls = existsSync(log)
      ? readFileSync(log, "utf8").trim().split("\n")
      : [];
    return { result, calls, ms: Date.now() - started };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("locks every running shell that has a lock target, and only those", () => {
  const { result, calls } = runLockSessions({
    FAKE_QS_INSTANCES: "11:lock,notifs 22:lock 33:notifs",
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.deepEqual(calls.sort(), [
    "ipc --pid 11 call lock lock",
    "ipc --pid 22 call lock lock",
  ]);
});

test("with no shell running it exits cleanly and calls nothing", () => {
  const { result, calls } = runLockSessions({ FAKE_QS_INSTANCES: "" });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.deepEqual(calls, []);
});
