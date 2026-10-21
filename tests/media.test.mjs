import { test } from "node:test";
import assert from "node:assert/strict";
import { selectPlayer, trackText } from "../shell/logic/media.mjs";

const p = (spec) =>
  spec.split(",").map((s) => {
    const [id, state] = s.split(":");
    return { id, state };
  });

// Spec table.
const TABLE = [
  ["a:paused", "a"],
  ["a:paused,b:playing", "b"],
  ["a:playing,b:playing", "a"],
  ["a:paused,b:stopped", "a"],
];

for (const [spec, expected] of TABLE) {
  test(`selectPlayer ${spec} -> ${expected}`, () => {
    assert.equal(selectPlayer(p(spec)), expected);
  });
}

test("selectPlayer gives null for an empty list", () => {
  assert.equal(selectPlayer([]), null);
});

test("selectPlayer switches when playback moves", () => {
  assert.equal(selectPlayer(p("a:playing,b:paused")), "a");
  assert.equal(selectPlayer(p("a:paused,b:playing")), "b");
});

const FB = {
  title: "Unknown title",
  album: "Unknown album",
  artist: "Unknown artist",
};

test("trackText keeps real metadata", () => {
  const meta = { title: "Song", album: "LP", artist: "Band" };
  assert.deepEqual(trackText(meta, FB), meta);
});

test("trackText falls back per missing or blank field", () => {
  assert.deepEqual(
    trackText({ title: "Song", album: "", artist: null }, FB),
    { title: "Song", album: "Unknown album", artist: "Unknown artist" },
  );
  assert.deepEqual(trackText({ title: "  " }, FB), FB);
});
