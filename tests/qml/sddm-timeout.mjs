import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("SDDM timeout and late results preserve authentication state", () => {
  const result = spawnSync("/usr/lib/qt6/bin/qml", [
    fileURLToPath(new URL("./sddm-timeout-probe.qml", import.meta.url)),
  ], {
    env: {
      ...process.env,
      QT_QPA_PLATFORM: "offscreen",
      QT_QUICK_BACKEND: "software",
    },
    encoding: "utf8",
    timeout: 10000,
  });
  // The probe exits 42 only when it reaches the end; the qml launcher can
  // otherwise exit successfully without actually running the probe.
  assert.equal(result.status, 42, result.stdout + result.stderr);
});
