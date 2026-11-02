import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const fixture = fileURLToPath(new URL("./exit-probe.qml", import.meta.url));
const run = (fail) =>
  spawnSync("qs", ["-p", fixture], {
    encoding: "utf8",
    timeout: 10000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_QML_TEST_FAIL: fail ? "1" : "0",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });

test("qs reports both success and failure for QML checks", () => {
  const success = run(false);
  assert.equal(success.status, 0, success.stderr);
  assert.match(success.stdout + success.stderr, /notch-qml-test: success/);
  const failure = run(true);
  assert.equal(failure.status, 7, failure.stderr);
  assert.match(
    failure.stdout + failure.stderr,
    /notch-qml-test: expected failure/,
  );
});

test("qs detects only the simulated tray item on a private bus", () => {
  const path = (name) => fileURLToPath(new URL(name, import.meta.url));
  const script = `
python3 "$1" &
fixture=$!
trap 'kill "$fixture" 2>/dev/null; wait "$fixture" 2>/dev/null' EXIT
qs -p "$2"
`;
  const result = spawnSync("dbus-run-session", [
    `--config-file=${path("./test-bus.conf")}`,
    "--",
    "sh",
    "-c",
    script,
    "tray-test",
    path("./fake_tray_item.py"),
    path("./tray-probe.qml"),
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      QT_QPA_PLATFORM: "offscreen",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(
    result.stdout + result.stderr,
    /notch-tray-test: simulated item detected/,
  );
});
