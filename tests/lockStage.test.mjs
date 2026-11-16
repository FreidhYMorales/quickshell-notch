import { test } from "node:test";
import assert from "node:assert/strict";
import {
  idleStageAction,
  inputEnds,
  lockLooks,
  movedPast,
} from "../shell/logic/lockStage.mjs";

test("the screensaver shows the wallpaper and the padlock notch, never the form", () => {
  assert.deepEqual(lockLooks("screensaver"), {
    wallpaper: true,
    content: false,
    notch: true,
  });
});

test("the black stage shows nothing at all", () => {
  assert.deepEqual(lockLooks("black"), {
    wallpaper: false,
    content: false,
    notch: false,
  });
});

test("a normal lock keeps today's look", () => {
  assert.deepEqual(lockLooks("normal"), {
    wallpaper: true,
    content: true,
    notch: true,
  });
});

test("an input in the screensaver goes straight to the lock form", () => {
  assert.deepEqual(inputEnds("screensaver"), {
    stage: "normal",
    blackFrame: false,
  });
});

test("an input in the black stage paints a black frame before the reveal", () => {
  assert.deepEqual(inputEnds("black"), {
    stage: "normal",
    blackFrame: true,
  });
});

test("an input in a normal lock changes nothing", () => {
  assert.deepEqual(inputEnds("normal"), {
    stage: "normal",
    blackFrame: false,
  });
});

test("the black stage darkens a locked session and locks an unlocked one", () => {
  assert.equal(idleStageAction(true), "black");
  assert.equal(idleStageAction(false), "lock");
});

test("a pointer that only lands on the surface is not a move", () => {
  assert.equal(movedPast({ x: 100, y: 100 }, { x: 100, y: 100 }, 4), false);
  assert.equal(movedPast({ x: 100, y: 100 }, { x: 102, y: 103 }, 4), false);
});

test("a pointer that moves a few pixels past the base is a real move", () => {
  assert.equal(movedPast({ x: 100, y: 100 }, { x: 105, y: 100 }, 4), true);
  assert.equal(movedPast({ x: 100, y: 100 }, { x: 100, y: 96 }, 4), true);
});
