import { test } from "node:test";
import assert from "node:assert/strict";
import { idleDelays } from "../shell/logic/idleState.mjs";

test("the lock waits screensaver + lock minutes and suspend waits all three", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 1, lock: 5, suspend: 15 }),
    { lockSec: 360, suspendSec: 1260 },
  );
  assert.deepEqual(
    idleDelays({ screensaver: 3, lock: 5, suspend: 15 }),
    { lockSec: 480, suspendSec: 1380 },
  );
});
