import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

test("wallpapers default to all monitors but individual remains selectable", () => {
  const result = spawnSync("qs", [
    "-p",
    fileURLToPath(new URL("./wallpaper-default.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 10000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      QT_QPA_PLATFORM: "wayland",
      QS_DISABLE_CRASH_HANDLER: "1",
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    }),
  });
  const log = result.stdout + result.stderr;
  assert.equal(result.status, 0, log);
  assert.match(log, /wallpaper all by default: true/);
  assert.match(log, /wallpaper individual selectable: true/);
});
