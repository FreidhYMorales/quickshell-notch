import { test } from "node:test";
import assert from "node:assert/strict";
import {
  idleDelays,
  parseIdle,
  serialiseIdle,
  stepMinutes,
} from "../shell/logic/idleState.mjs";

test("the screensaver starts at its minutes, the black stage waits screensaver + lock and suspend waits all three", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 1, lock: 5, suspend: 15 }),
    { screensaverSec: 60, lockSec: 360, suspendSec: 1260 },
  );
  assert.deepEqual(
    idleDelays({ screensaver: 3, lock: 5, suspend: 15 }),
    { screensaverSec: 180, lockSec: 480, suspendSec: 1380 },
  );
});

test("a zero stage turns its step off without stopping the other", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 1, lock: 5, suspend: 0 }),
    { screensaverSec: 60, lockSec: 360, suspendSec: null },
  );
  assert.deepEqual(
    idleDelays({ screensaver: 0, lock: 0, suspend: 15 }),
    { screensaverSec: null, lockSec: null, suspendSec: 900 },
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

test("a zero lock timeout turns the black stage off even with screensaver minutes", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 3, lock: 0, suspend: 15 }),
    { screensaverSec: 180, lockSec: null, suspendSec: 1080 },
  );
});

test("a zero screensaver timeout turns the screensaver phase off but still locks and suspends", () => {
  assert.deepEqual(
    idleDelays({ screensaver: 0, lock: 5, suspend: 15 }),
    { screensaverSec: null, lockSec: 300, suspendSec: 1200 },
  );
});

test("a step keeps the minutes between 0 and 60", () => {
  assert.equal(stepMinutes(5, 1), 6);
  assert.equal(stepMinutes(5, -1), 4);
  assert.equal(stepMinutes(60, 1), 60);
  assert.equal(stepMinutes(0, -1), 0);
});

test("saving idle state keeps the old field names and adds the wallpaper choice", () => {
  assert.deepEqual(
    serialiseIdle({ screensaver: 2, lock: 4, suspend: 0 }, {
      sameAsDesktop: false,
      path: "/w/a.png",
    }),
    {
      screensaverTimeoutMin: 2,
      lockTimeoutMin: 4,
      suspendTimeoutMin: 0,
      screensaverUseWallpaper: false,
      screensaverPath: "/w/a.png",
    },
  );
  assert.deepEqual(
    serialiseIdle({ screensaver: 3, lock: 5, suspend: 15 }, {
      sameAsDesktop: true,
      path: "",
    }),
    {
      screensaverTimeoutMin: 3,
      lockTimeoutMin: 5,
      suspendTimeoutMin: 15,
      screensaverUseWallpaper: true,
      screensaverPath: "",
    },
  );
});
