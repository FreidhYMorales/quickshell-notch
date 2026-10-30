import { test } from "node:test";
import assert from "node:assert/strict";
import { addToHistory } from "../shell/logic/notifHistory.mjs";

const n = (id, summary) => ({ id, summary });

test("addToHistory puts the newest first", () => {
  const history = addToHistory(addToHistory([], n(1, "a"), 50), n(2, "b"), 50);
  assert.deepEqual(history, [n(2, "b"), n(1, "a")]);
});

test("addToHistory refreshes a known id where it already is", () => {
  const start = [n(3, "c"), n(2, "b"), n(1, "a")];
  const history = addToHistory(start, n(2, "b2"), 50);
  assert.deepEqual(history, [n(3, "c"), n(2, "b2"), n(1, "a")]);
});

test("addToHistory drops the oldest past the cap", () => {
  const start = [n(3, "c"), n(2, "b"), n(1, "a")];
  assert.deepEqual(addToHistory(start, n(4, "d"), 3), [
    n(4, "d"),
    n(3, "c"),
    n(2, "b"),
  ]);
});
