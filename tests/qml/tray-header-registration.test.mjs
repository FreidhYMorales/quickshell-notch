import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("qml checks include the tray menu header probe", () => {
  const result = spawnSync("make", ["-n", "qml-test"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /tests\/qml\/tray-menu-header\.mjs/);
});
