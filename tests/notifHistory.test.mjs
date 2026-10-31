import { test } from "node:test";
import assert from "node:assert/strict";
import {
  addToHistory,
  latest,
  removeFromHistory,
} from "../shell/logic/notifHistory.mjs";

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

test("removeFromHistory drops the closed id", () => {
  const start = [n(3, "c"), n(2, "b"), n(1, "a")];
  assert.deepEqual(removeFromHistory(start, 2), [n(3, "c"), n(1, "a")]);
});

test("removeFromHistory leaves the list alone for an unknown id", () => {
  const start = [n(3, "c"), n(1, "a")];
  assert.deepEqual(removeFromHistory(start, 9), [n(3, "c"), n(1, "a")]);
});

test("latest shows only the newest 3 of 5", () => {
  const start = [n(5, "e"), n(4, "d"), n(3, "c"), n(2, "b"), n(1, "a")];
  assert.deepEqual(latest(start, 3), [n(5, "e"), n(4, "d"), n(3, "c")]);
});

test("latest shows all of a shorter history", () => {
  const start = [n(2, "b"), n(1, "a")];
  assert.deepEqual(latest(start, 3), [n(2, "b"), n(1, "a")]);
});
