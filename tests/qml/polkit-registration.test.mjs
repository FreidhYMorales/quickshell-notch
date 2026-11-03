import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("qml checks run polkit probes serially", () => {
  const result = spawnSync("make", ["-n", "qml-test"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.match(
    result.stdout,
    /node --test --test-concurrency=1 tests\/qml\/polkit-\*\.mjs/,
  );
});
