import { test } from "node:test";
import assert from "node:assert/strict";
import {
  idleStageAction,
  inputEnds,
  lockLooks,
  movedPast,
  outputsAwake,
  stageEffects,
  wakeReady,
} from "../shell/logic/lockStage.mjs";
import * as LockStageModule from "../shell/logic/lockStage.mjs";

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

test("the screensaver hides the pointer and the black stage turns the outputs off", () => {
  assert.deepEqual(stageEffects("screensaver"), {
    overlay: "wallpaper",
    pointerHidden: true,
    outputsOn: true,
  });
  assert.deepEqual(stageEffects("black"), {
    overlay: "black",
    pointerHidden: true,
    outputsOn: false,
  });
});

test("a normal lock has no overlay and asks for neither the pointer nor the outputs", () => {
  assert.deepEqual(stageEffects("normal"), {
    overlay: null,
    pointerHidden: false,
    outputsOn: true,
  });
});

test("a manual lock during the screensaver takes the wallpaper layer down", () => {
  // The session stays locked and the stage goes back to normal without an
  // input, so nothing may keep covering the form.
  assert.equal(
    LockStageModule.overlayMustContract("wallpaper", "normal"),
    true,
  );
  assert.equal(LockStageModule.overlayMustContract("black", "normal"), true);
});

test("a stage that paints its own layer does not need a contraction", () => {
  assert.equal(LockStageModule.overlayMustContract("", "screensaver"), false);
  assert.equal(
    LockStageModule.overlayMustContract("wallpaper", "screensaver"),
    false,
  );
  assert.equal(
    LockStageModule.overlayMustContract("wallpaper", "black"),
    false,
  );
});

test("nothing is contracted when no layer was painted", () => {
  assert.equal(LockStageModule.overlayMustContract("", "normal"), false);
});

test("the outputs are awake only when every monitor reports dpms on", () => {
  assert.equal(outputsAwake('[{"name":"DP-1","dpmsStatus":true}]'), true);
  assert.equal(
    outputsAwake(
      '[{"name":"DP-1","dpmsStatus":true},{"name":"HDMI-A-1","dpmsStatus":false}]',
    ),
    false,
  );
});

test("unreadable output state counts as awake so the lock never stalls", () => {
  assert.equal(outputsAwake(""), true);
  assert.equal(outputsAwake("not json"), true);
  assert.equal(outputsAwake("[]"), true);
  assert.equal(outputsAwake('[{"name":"DP-1"}]'), true);
});

test("the black stage waits for the panel and for the outputs to be back", () => {
  const off = '[{"name":"DP-1","dpmsStatus":false}]';
  const on = '[{"name":"DP-1","dpmsStatus":true}]';
  // Still inside the panel's wake time: never contract yet.
  assert.equal(wakeReady(0, on, 900, 5000), false);
  assert.equal(wakeReady(899, on, 900, 5000), false);
  // Panel had its time, but the compositor says the outputs are still off.
  assert.equal(wakeReady(900, off, 900, 5000), false);
  // Both conditions met.
  assert.equal(wakeReady(900, on, 900, 5000), true);
  // A compositor that never reports on does not hold the lock black forever.
  assert.equal(wakeReady(5000, off, 900, 5000), true);
});
