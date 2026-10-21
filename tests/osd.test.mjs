import { test } from "node:test";
import assert from "node:assert/strict";
import { shouldReveal } from "../shell/logic/osd.mjs";

const s = (over) =>
  Object.assign(
    { available: true, source: "sink-1", value: 0.5, muted: false },
    over,
  );

const rows = [
  ["value change", s(), s({ value: 0.55 }), true],
  ["mute toggled on", s(), s({ muted: true }), true],
  ["mute toggled off", s({ muted: true }), s(), true],
  ["value and mute both change", s(), s({ value: 0.1, muted: true }), true],
  ["no change", s(), s(), false],
  ["float noise below epsilon", s(), s({ value: 0.5 + 1e-9 }), false],
  ["value above 100% still counts", s({ value: 1.2 }), s({ value: 1.3 }), true],
  [
    "default sink switch with a different value",
    s(),
    s({
      source: "sink-2",
      value: 0.9,
    }),
    false,
  ],
  [
    "default sink switch with a mute difference",
    s(),
    s({
      source: "sink-2",
      muted: true,
    }),
    false,
  ],
  [
    "became available (initial read)",
    s({ available: false, value: 0 }),
    s(),
    false,
  ],
  ["became unavailable", s(), s({ available: false }), false],
  [
    "unavailable both, value differs",
    s({ available: false }),
    s({
      available: false,
      value: 0.9,
    }),
    false,
  ],
  ["no previous sample", null, s(), false],
  ["no next sample", s(), null, false],
  ["both missing", undefined, undefined, false],
  [
    "null source on both sides",
    s({ source: null }),
    s({
      source: null,
      value: 0.7,
    }),
    true,
  ],
];
for (const [name, prev, next, want] of rows) {
  test(`shouldReveal: ${name} -> ${want}`, () => {
    assert.equal(shouldReveal(prev, next), want);
  });
}
