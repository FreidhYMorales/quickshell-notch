import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const qs = spawnSync("which", ["qs"], { encoding: "utf8" }).stdout.trim();

test("without matugen the notch falls back to neutral greys", () => {
  const result = spawnSync(qs, [
    "-p",
    fileURLToPath(new URL("./theme-fallback.qml", import.meta.url)),
  ], {
    encoding: "utf8",
    timeout: 15000,
    env: Object.assign({}, process.env, {
      NOTCH_SMOKE: "1",
      QT_QPA_PLATFORM: "wayland",
      NO_COLOR: "1",
      QS_DISABLE_CRASH_HANDLER: "1",
      NOTCH_CONFIG_URL: new URL("../../shell/config", import.meta.url).href,
    }),
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  const found = output.match(
    /fallback: (#[0-9a-f]{6}) (#[0-9a-f]{6}) (#[0-9a-f]{6})/i,
  );
  assert.ok(found, output);
  for (const hex of found.slice(1)) {
    const [red, green, blue] = [
      hex.slice(1, 3),
      hex.slice(3, 5),
      hex.slice(5, 7),
    ];
    assert.equal(red, green, hex);
    assert.equal(green, blue, hex);
  }
});
