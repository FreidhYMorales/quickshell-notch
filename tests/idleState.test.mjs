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

test("a zero stage turns its step off without stopping the other", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 1, lock: 5, suspend: 0 }),
    { lockSec: 360, suspendSec: null },
  );
  assert.deepEqual(
    idleDelays({ screensaver: 0, lock: 0, suspend: 15 }),
    { lockSec: null, suspendSec: 900 },
  );
});
