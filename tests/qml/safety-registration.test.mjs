import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("qml checks include both crash-relaunch safety tests", () => {
  const result = spawnSync("make", ["-n", "qml-test"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /tests\/qml\/tray-runner-safety\.mjs/);
  assert.match(result.stdout, /tests\/qml\/other-runners-safety\.mjs/);
});
