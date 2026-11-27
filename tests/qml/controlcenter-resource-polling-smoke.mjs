import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("smoke mode keeps resource telemetry unpolled with the control center open", () => {
  const result = spawnSync("qs", [
    "-p",
    new URL("./controlcenter-resource-polling-smoke.qml", import.meta.url)
      .pathname,
  ], {
    encoding: "utf8",
    timeout: 8000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_CC_URL:
        new URL("../../shell/notches/controlcenter", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
});
