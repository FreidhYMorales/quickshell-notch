import { test } from "node:test";
import assert from "node:assert/strict";
import {
  monitorRetryDelay,
  parsePreparingForSleep,
  parseSleepSignal,
  sleepStep,
} from "../shell/logic/sleepLock.mjs";

test("the logind property reply reports an in-progress sleep", () => {
  assert.equal(parsePreparingForSleep("(<true>,)"), true);
  assert.equal(parsePreparingForSleep("(<false>,)"), false);
  assert.equal(parsePreparingForSleep("not a property reply"), null);
});

test("monitor retry delay backs off and stays bounded", () => {
  assert.deepEqual(
    [1, 2, 3, 4, 5, 6, 20].map(monitorRetryDelay),
    [250, 500, 1000, 2000, 4000, 5000, 5000],
  );
});

const prefix =
  "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep ";

test("PrepareForSleep lines from gdbus monitor give the sleep direction", () => {
  assert.equal(parseSleepSignal(prefix + "(true,)"), true);
  assert.equal(parseSleepSignal(prefix + "(false,)"), false);
});

test("any other monitor line is not a sleep signal", () => {
  assert.equal(
    parseSleepSignal(
      "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForShutdown (true,)",
    ),
    null,
  );
  assert.equal(
    parseSleepSignal(
      "Monitoring signals on object /org/freedesktop/login1 owned by org.freedesktop.login1",
    ),
    null,
  );
});

const awake = { sleeping: false, locked: false };

test("going to sleep unlocked asks for the lock and keeps the inhibitor", () => {
  assert.deepEqual(sleepStep(awake, { type: "PrepareForSleep", on: true }), {
    sleeping: true,
    locked: false,
    requestLock: true,
    inhibit: true,
  });
});

test("the confirmed lock while going to sleep releases the inhibitor", () => {
  assert.deepEqual(
    sleepStep({ sleeping: true, locked: false }, { type: "Locked", on: true }),
    { sleeping: true, locked: true, requestLock: false, inhibit: false },
  );
});

test("going to sleep already locked releases the inhibitor at once", () => {
  assert.deepEqual(
    sleepStep({ sleeping: false, locked: true }, {
      type: "PrepareForSleep",
      on: true,
    }),
    { sleeping: true, locked: true, requestLock: false, inhibit: false },
  );
});

test("resuming takes the inhibitor again, and locking while awake keeps it", () => {
  assert.deepEqual(
    sleepStep({ sleeping: true, locked: true }, {
      type: "PrepareForSleep",
      on: false,
    }),
    { sleeping: false, locked: true, requestLock: false, inhibit: true },
  );
  assert.deepEqual(sleepStep(awake, { type: "Locked", on: true }), {
    sleeping: false,
    locked: true,
    requestLock: false,
    inhibit: true,
  });
});
