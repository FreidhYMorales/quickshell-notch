import { test } from "node:test";
import assert from "node:assert/strict";
import { parseLevel, percentOf, setArgs } from "../shell/logic/brightness.mjs";

test("parseLevel accepts a plain non-negative integer line", () => {
  assert.equal(parseLevel("96"), 96);
  assert.equal(parseLevel("0"), 0);
  assert.equal(parseLevel("  255\n"), 255);
});

test("parseLevel rejects garbage with null", () => {
  for (
    const bad of [
      "",
      "   ",
      "-5",
      "1.5",
      "1e3",
      "0x10",
      "50%",
      "50 60",
      "abc",
      "NaN",
      "Infinity",
      "99999999999999999999",
      null,
      undefined,
      42,
      {},
    ]
  ) {
    assert.equal(parseLevel(bad), null, `input ${String(bad)}`);
  }
});

test("percentOf follows the spec table", () => {
  assert.equal(percentOf(50, 100), 50);
  assert.equal(percentOf(96, 255), 38);
  assert.equal(percentOf(0, 255), 0);
  assert.equal(percentOf(255, 255), 100);
});

test("percentOf clamps a current above max", () => {
  assert.equal(percentOf(300, 255), 100);
});

test("percentOf returns null on unusable input", () => {
  for (
    const [c, m] of [
      [5, 0],
      [5, -1],
      [-1, 100],
      [null, 100],
      [5, null],
      [NaN, 100],
      [5, NaN],
      [Infinity, 100],
      [5, Infinity],
      ["5", 100],
      [undefined, undefined],
    ]
  ) {
    assert.equal(percentOf(c, m), null, `${String(c)}/${String(m)}`);
  }
});

test("setArgs follows the spec table", () => {
  assert.deepEqual(setArgs(-5), ["brightnessctl", "set", "0%"]);
  assert.deepEqual(setArgs(42.6), ["brightnessctl", "set", "43%"]);
  assert.deepEqual(setArgs(130), ["brightnessctl", "set", "100%"]);
  assert.deepEqual(setArgs(500), ["brightnessctl", "set", "100%"]);
  assert.deepEqual(setArgs(0), ["brightnessctl", "set", "0%"]);
  assert.deepEqual(setArgs(100), ["brightnessctl", "set", "100%"]);
});

test("setArgs never lets non-numbers reach argv", () => {
  for (
    const bad of [
      "50; rm",
      "50",
      "50%",
      NaN,
      Infinity,
      -Infinity,
      null,
      undefined,
      {},
      [50],
      true,
    ]
  ) {
    assert.equal(setArgs(bad), null, `input ${String(bad)}`);
  }
});

test("setArgs output is integer-only", () => {
  for (const p of [-0.4, 0.5, 33.333, 99.5, 1e-9, 12345.678]) {
    const arg = setArgs(p)[2];
    assert.match(arg, /^(100|[1-9]?\d)%$/, `input ${p}`);
  }
});
