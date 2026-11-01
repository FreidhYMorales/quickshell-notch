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
