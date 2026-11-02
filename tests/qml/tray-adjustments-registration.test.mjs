import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("qml checks include the tray menu adjustment probes", () => {
  const result = spawnSync("make", ["-n", "qml-test"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /tests\/qml\/tray-menu-look\.mjs/);
  assert.match(result.stdout, /tests\/qml\/tray-menu-hover\.mjs/);
  assert.match(result.stdout, /tests\/qml\/tray-menu-toggle\.mjs/);
  assert.match(result.stdout, /tests\/qml\/tray-menu-leave\.mjs/);
});
