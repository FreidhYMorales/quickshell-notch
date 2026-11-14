import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("a missing helper shows it as unavailable instead of hanging", () => {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./launcher-webapp-missing.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 30000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "0",
      NOTCH_LAUNCH_DRY_RUN: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
      // No ~/.local/bin: the helper is not installed on this run.
      PATH: "/usr/bin:/bin",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /webapp missing: helper reported as unavailable/);
});
