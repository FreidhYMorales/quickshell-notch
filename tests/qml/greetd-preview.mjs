import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const QML = "/usr/lib/qt6/bin/qml";
const ENV = {
  QT_QPA_PLATFORM: "offscreen",
  QT_QUICK_BACKEND: "software",
};

test("the greeter compresses while authentication is pending and waits for success", () => {
  const result = spawnSync(QML, [
    fileURLToPath(new URL("./greetd-wait-morph-probe.qml", import.meta.url)),
  ], { env: { ...process.env, ...ENV }, encoding: "utf8", timeout: 5000 });
  assert.equal(result.status, 42, result.stdout + result.stderr);
});

test("an additional PAM prompt expands the waiting greeter", () => {
  const result = spawnSync(QML, [
    fileURLToPath(new URL("./greetd-extra-prompt-probe.qml", import.meta.url)),
  ], { env: { ...process.env, ...ENV }, encoding: "utf8", timeout: 5000 });
  assert.equal(result.status, 42, result.stdout + result.stderr);
});

test("a stalled authentication stays pending and accepts a late success", () => {
  const result = spawnSync(QML, [
    fileURLToPath(new URL("./greetd-timeout-probe.qml", import.meta.url)),
  ], { env: { ...process.env, ...ENV }, encoding: "utf8", timeout: 5000 });
  assert.equal(result.status, 42, result.stdout + result.stderr);
});

test("greetd visual simulation waits for auth before animating", () => {
  const result = spawnSync(QML, [
    fileURLToPath(new URL("./greetd-preview-probe.qml", import.meta.url)),
  ], {
    env: { ...process.env, ...ENV },
    encoding: "utf8",
    timeout: 15000,
  });
  assert.equal(result.status, 42, result.stdout + result.stderr);
});

for (
  const [mode, tokens] of [
    [
      "themed",
      ["file:///home/example/my wallpaper.gif", "#123456", "#abcdef", "420"],
    ],
    ["default", ["-", "-", "-", "-"]],
  ]
) {
  test(`greetd preview applies the launcher's ${mode} visual tokens`, () => {
    const result = spawnSync(QML, [
      fileURLToPath(new URL("./greetd-token-probe.qml", import.meta.url)),
      "--",
      "notch-preview",
      ...tokens,
      "notch-expect",
      mode,
    ], {
      env: { ...process.env, ...ENV },
      encoding: "utf8",
      timeout: 15000,
    });
    assert.equal(result.status, 42, result.stdout + result.stderr);
  });
}
