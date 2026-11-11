import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

test("the lock captures frames in memory instead of spawning grim", () => {
  const source = readFileSync(
    new URL("../../shell/lock/Lock.qml", import.meta.url),
    "utf8",
  );
  assert.match(source, /LockFrameGate/);
  assert.doesNotMatch(source, /grim/);
});
