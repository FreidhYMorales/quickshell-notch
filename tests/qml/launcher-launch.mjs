import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./launcher-launch.qml", import.meta.url));

test("activating the selected app launches it (dry run) and closes", () => {
  const result = spawnSync("qs", ["-p", probe], {
    encoding: "utf8",
    timeout: 20000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      NOTCH_CENTER_URL:
        new URL("../../shell/notches/center", import.meta.url).href,
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  const expected = output.match(/launcher launch: expect (\S+)/);
  assert.ok(expected, output);
  assert.match(output, new RegExp(`Apps: launch ${expected[1]}\\b`));
  assert.match(output, /launcher launch: closed/);
});
