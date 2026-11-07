import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(
  new URL("./controlcenter-tiles.qml", import.meta.url),
);

test("the control center shows the caffeine tile off and hides the profile tile without a backend", () => {
  const result = spawnSync("qs", ["-p", probe], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_CC_URL: new URL(
        "../../shell/notches/controlcenter",
        import.meta.url,
      ).href,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /cc tiles: caffeine off, profile hidden, caffeine lit/);
});
