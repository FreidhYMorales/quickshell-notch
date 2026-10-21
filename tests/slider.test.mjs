import { test } from "node:test";
import assert from "node:assert/strict";
import {
  accumulateWheel,
  clamp,
  displayPercent,
  levelGlyph,
  notchesOf,
  positionOf,
  valueAt,
  wheel,
} from "../shell/logic/slider.mjs";

const vol = { track: 200, min: 0, max: 1 };
const bri = { track: 200, min: 0, max: 100 };

test("clamp bounds a value to the range", () => {
  for (
    const [v, want] of [[-1, 0], [0, 0], [0.4, 0.4], [1, 1], [9, 1]]
  ) assert.equal(clamp(v, 0, 1), want, `clamp(${v})`);
});

// Spec: value -> position (track 200, range 0..1)
for (const [v, pos] of [[0, 0], [0.5, 100], [1, 200], [1.3, 200], [-2, 0]]) {
  test(`positionOf(${v}) on volume = ${pos}`, () => {
    assert.equal(positionOf(v, vol), pos);
  });
}

// Spec: position -> value (range 0..100, track 200)
for (const [pos, v] of [[-10, 0], [0, 0], [50, 25], [100, 50], [250, 100]]) {
  test(`valueAt(${pos}) on brightness = ${v}`, () => {
    assert.equal(valueAt(pos, bri), v);
  });
}

test("tap at 150 px then drag to -20 px (volume): 0.75 then 0", () => {
  assert.equal(valueAt(150, vol), 0.75);
  assert.equal(valueAt(-20, vol), 0);
});

test("valueAt rounds to 3 decimals (no float noise)", () => {
  assert.equal(valueAt(66.6666, vol), 0.333);
});

test("degenerate track or range: no division by zero", () => {
  assert.equal(valueAt(10, { track: 0, min: 0, max: 1 }), 0);
  assert.equal(positionOf(0.5, { track: 0, min: 0, max: 1 }), 0);
  assert.equal(positionOf(0.5, { track: 200, min: 1, max: 1 }), 0);
});

test("positionOf and valueAt round-trip", () => {
  for (const v of [0, 0.25, 0.5, 0.75, 1]) {
    assert.equal(valueAt(positionOf(v, vol), vol), v);
  }
});

// Spec wheel table (step 0.05) plus brightness (step 5)
const wheelRows = [
  [0.5, 1, { step: 0.05, min: 0, max: 1 }, 0.55],
  [0.98, 1, { step: 0.05, min: 0, max: 1 }, 1],
  [0.02, -1, { step: 0.05, min: 0, max: 1 }, 0],
  [0.55, 2, { step: 0.05, min: 0, max: 1 }, 0.65],
  [0.7, 0, { step: 0.05, min: 0, max: 1 }, 0.7],
  [50, 1, { step: 5, min: 0, max: 100 }, 55],
  [98, 1, { step: 5, min: 0, max: 100 }, 100],
  [3, -1, { step: 5, min: 0, max: 100 }, 0],
];
for (const [value, n, opts, want] of wheelRows) {
  test(`wheel(${value}, ${n}, step ${opts.step}) = ${want}`, () => {
    assert.equal(wheel(value, n, opts), want);
  });
}

test("wheel rounds away float noise (0.1 + 0.2 style)", () => {
  assert.equal(wheel(0.55, 1, { step: 0.05, min: 0, max: 1 }), 0.6);
  assert.equal(wheel(0.1, 3, { step: 0.05, min: 0, max: 1 }), 0.25);
});

test("notchesOf: +-1 per 120 of angle delta, partial deltas are 0", () => {
  for (
    const [d, n] of [[120, 1], [-120, -1], [240, 2], [-360, -3], [0, 0], [
      60,
      0,
    ], [-119, 0]]
  ) assert.equal(notchesOf(d), n, `notchesOf(${d})`);
});

test("notchesOf never returns negative zero", () => {
  assert.equal(Object.is(notchesOf(-60), 0), true);
});

const glyphs = { muted: "M", low: "L", mid: "D", high: "H" };
const lv = { high: 0.66, mid: 0.33 };
const glyphRows = [
  [0, false, "L"],
  [0.32, false, "L"],
  [0.33, false, "D"],
  [0.65, false, "D"],
  [0.66, false, "H"],
  [1, false, "H"],
  [1.3, false, "H"],
  [0.9, true, "M"],
  [0, true, "M"],
];
for (const [f, muted, want] of glyphRows) {
  test(`levelGlyph(${f}, muted ${muted}) = ${want}`, () => {
    assert.equal(levelGlyph(f, muted, lv, glyphs), want);
  });
}

// displayPercent: the label is NOT clamped (volume above 100% shows the real number).
const pctRows = [
  [0, vol, 0],
  [0.5, vol, 50],
  [1, vol, 100],
  [1.3, vol, 130],
  [0.555, vol, 56],
  [37, bri, 37],
  [100, bri, 100],
  [-0.2, vol, 0],
];
for (const [v, geo, want] of pctRows) {
  test(`displayPercent(${v}, 0..${geo.max}) = ${want}`, () => {
    assert.equal(displayPercent(v, geo), want);
  });
}

test("above 100%: bar is full while the label keeps the real percent", () => {
  assert.equal(positionOf(1.3, vol), vol.track);
  assert.equal(displayPercent(1.3, vol), 130);
});

// Touchpads send many small angle deltas (e.g. 15); keep the remainder so
// they add up to whole notches instead of being dropped.
test("accumulateWheel: small touchpad deltas add up to whole notches", () => {
  let carry = 0;
  let total = 0;
  for (let i = 0; i < 16; i++) {
    const r = accumulateWheel(carry, 15);
    carry = r.carry;
    total += r.notches;
  }
  assert.equal(total, 2); // 16 * 15 = 240 = two notches
  assert.equal(carry, 0);
});

test("accumulateWheel: a mouse notch steps at once; direction changes reset the remainder", () => {
  assert.deepEqual(accumulateWheel(0, 120), { notches: 1, carry: 0 });
  assert.deepEqual(accumulateWheel(0, -240), { notches: -2, carry: 0 });
  assert.deepEqual(accumulateWheel(90, 45), { notches: 1, carry: 15 });
  assert.deepEqual(accumulateWheel(90, -30), { notches: 0, carry: -30 });
  assert.equal(Object.is(accumulateWheel(0, -60).notches, 0), true);
});
