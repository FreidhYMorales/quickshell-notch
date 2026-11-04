import { test } from "node:test";
import assert from "node:assert/strict";
import { parseSleepSignal } from "../shell/logic/sleepLock.mjs";

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
