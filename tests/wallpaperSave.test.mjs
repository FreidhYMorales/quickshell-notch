import { test } from "node:test";
import assert from "node:assert/strict";
import {
  advanceSave,
  enqueueSave,
  failSave,
  initialSaveQueue,
  startSave,
} from "../shell/logic/wallpaperSave.mjs";

test("writes the same snapshot through both files", () => {
  const original = { "DP-1": "/w/a.png" };
  let queue = enqueueSave(initialSaveQueue(), "/w/base.png", original);
  original["DP-1"] = "/w/changed.png";
  queue = startSave(queue);
  assert.equal(queue.active.perScreen["DP-1"], "/w/a.png");
  queue = advanceSave(queue, "mkdir");
  assert.equal(queue.phase, "default");
  queue = advanceSave(queue, "default");
  assert.equal(queue.phase, "screens");
  queue = advanceSave(queue, "screens");
  assert.equal(queue.saved, true);
});

test("new edits wait for active snapshot then flush", () => {
  let queue = startSave(enqueueSave(initialSaveQueue(), "/w/one.png", {}));
  queue = enqueueSave(queue, "/w/two.png", { "DP-1": "/w/two.png" });
  assert.equal(startSave(queue).active.fallback, "/w/one.png");
  queue = advanceSave(
    advanceSave(advanceSave(queue, "mkdir"), "default"),
    "screens",
  );
  assert.equal(queue.saved, false);
  queue = startSave(queue);
  assert.equal(queue.active.fallback, "/w/two.png");
  queue = advanceSave(
    advanceSave(advanceSave(queue, "mkdir"), "default"),
    "screens",
  );
  assert.equal(queue.saved, true);
});

test("failure retains the snapshot for an explicit retry", () => {
  let queue = startSave(enqueueSave(initialSaveQueue(), "/w/a.png", {}));
  queue = advanceSave(queue, "mkdir");
  queue = failSave(queue);
  assert.equal(queue.saved, false);
  assert.equal(queue.pending.fallback, "/w/a.png");
  queue = startSave(queue);
  assert.equal(queue.phase, "mkdir");
});

test("newer changes supersede failed snapshots", () => {
  let queue = startSave(enqueueSave(initialSaveQueue(), "/w/old.png", {}));
  queue = enqueueSave(queue, "/w/new.png", {});
  queue = failSave(queue);
  assert.equal(queue.pending.fallback, "/w/new.png");
});

test("out of order callbacks do not advance a write", () => {
  const queue = startSave(enqueueSave(initialSaveQueue(), "/w/a.png", {}));
  assert.equal(advanceSave(queue, "screens"), queue);
});
