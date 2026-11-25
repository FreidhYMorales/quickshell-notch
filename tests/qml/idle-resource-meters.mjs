import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("idle center shows only date and time without resource meters", () => {
  const result = spawnSync("qs", [
    "-p",
    new URL("./idle-resource-meters.qml", import.meta.url).pathname,
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
});
