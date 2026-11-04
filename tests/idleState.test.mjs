import { test } from "node:test";
import assert from "node:assert/strict";
import { idleDelays, parseIdle } from "../shell/logic/idleState.mjs";

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

const oldIdle =
  '{"screensaverTimeoutMin":1,"lockTimeoutMin":5,"suspendTimeoutMin":15,"screensaverUseWallpaper":true,"screensaverPath":"/x.png"}';

test("the saved idle state gives its three timeouts", () => {
  assert.deepEqual(parseIdle(oldIdle), {
    screensaver: 1,
    lock: 5,
    suspend: 15,
  });
});

test("a missing timeout takes the old default", () => {
  assert.deepEqual(
    parseIdle('{"screensaverTimeoutMin":1,"suspendTimeoutMin":0}'),
    { screensaver: 1, lock: 5, suspend: 0 },
  );
});

test("a missing or broken idle state uses the defaults 3/5/15", () => {
  const defaults = { screensaver: 3, lock: 5, suspend: 15 };
  assert.deepEqual(parseIdle(null), defaults);
  assert.deepEqual(parseIdle("not json"), defaults);
});
