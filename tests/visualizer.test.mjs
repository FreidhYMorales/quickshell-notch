import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  barGeometry,
  cavaConfig,
  parseFrame,
  pickAccent,
} from "../shell/logic/visualizer.mjs";

const EXPECTED = [
  "[general]",
  "bars = 6",
  "framerate = 30",
  "autosens = 1",
  "[output]",
  "method = raw",
  "raw_target = /dev/stdout",
  "data_format = ascii",
  "ascii_max_range = 100",
  "bar_delimiter = 59",
  "frame_delimiter = 10",
  "channels = mono",
  "",
].join("\n");

test("cavaConfig emits the expected text", () => {
  assert.equal(
    cavaConfig({ bars: 6, framerate: 30, maxRange: 100 }),
    EXPECTED,
  );
});

// [input, expected bars, framerate, maxRange]
for (
  const [input, bars, fps, range] of [
    [{ bars: 0, framerate: 0, maxRange: 0 }, 1, 1, 1],
    [{ bars: 999, framerate: 999, maxRange: 99999 }, 64, 60, 1000],
    [{ bars: -5, framerate: -1, maxRange: -9 }, 1, 1, 1],
    [{ bars: 6.9, framerate: 30.5, maxRange: 100.2 }, 6, 30, 100],
    [{ bars: NaN, framerate: undefined, maxRange: "x" }, 1, 1, 1],
  ]
) {
  test(`cavaConfig clamps ${JSON.stringify(input)}`, () => {
    const text = cavaConfig(input);
    assert.match(text, new RegExp(`^bars = ${bars}$`, "m"));
    assert.match(text, new RegExp(`^framerate = ${fps}$`, "m"));
    assert.match(text, new RegExp(`^ascii_max_range = ${range}$`, "m"));
  });
}

test("cavaConfig is injection-proof", () => {
  const text = cavaConfig({
    bars: "6\n[output]\nmethod = noncurses",
    framerate: "30\n[x]",
    maxRange: "100;rm",
  });
  assert.equal(text.split("[output]").length, 2);
  assert.equal(text.split("\n").length, EXPECTED.split("\n").length);
  assert.doesNotMatch(text, /noncurses|\[x\]|;rm/);
});

// [line, expected]
for (
  const [line, expected] of [
    ["0;50;100;", [0, 0.5, 1]],
    ["0;50;100", [0, 0.5, 1]],
    ["200;30;0;", [1, 0.3, 0]],
    ["0;50;", null],
    ["0;50;100;7;", null],
    ["", null],
    ["1;x;3;", null],
    ["-1;2;3;", null],
    ["1;;3;", null],
    [null, null],
  ]
) {
  test(`parseFrame ${JSON.stringify(line)} (3 bars, max 100)`, () => {
    assert.deepEqual(parseFrame(line, 3, 100), expected);
  });
}

test("parseFrame accepts the real cava frame", () => {
  const line = readFileSync(
    new URL("./fixtures/cava-frame.txt", import.meta.url),
    "utf8",
  ).trim();
  assert.deepEqual(parseFrame(line, 6, 100), [0, 0, 0, 0, 0, 0]);
});

const geo = { height: 20, barWidth: 3, gap: 2, minHeight: 2 };

test("barGeometry: all-zero is a flat line minHeight thick", () => {
  assert.deepEqual(barGeometry([0, 0], geo), [
    { x: 0, y: 9, height: 2 },
    { x: 5, y: 9, height: 2 },
  ]);
});

test("barGeometry: mirrored around the centre line", () => {
  const bars = barGeometry([1, 0.5, 0.25], geo);
  assert.deepEqual(bars.map((b) => b.height), [20, 10, 5]);
  for (const b of bars) {
    assert.equal(b.y, (geo.height - b.height) / 2);
    assert.equal(b.y + b.height / 2, geo.height / 2);
  }
});

test("barGeometry: x spacing and empty input", () => {
  assert.deepEqual(barGeometry([0, 0, 0], geo).map((b) => b.x), [0, 5, 10]);
  assert.deepEqual(barGeometry([], geo), []);
});

const c = (r, g, b) => ({ r, g, b });

test("pickAccent picks the most saturated bright colour", () => {
  const list = [c(0.5, 0.4, 0.4), c(0.9, 0.2, 0.2), c(0.6, 0.5, 0.3)];
  assert.equal(pickAccent(list, { minLuma: 0.2 }), 1);
});

test("pickAccent rejects greys and darks", () => {
  const list = [c(0.5, 0.5, 0.5), c(0.9, 0.9, 0.9), c(0.1, 0, 0), c(0, 0, 0.1)];
  assert.equal(pickAccent(list, { minLuma: 0.2 }), -1);
});

test("pickAccent skips a saturated dark colour for a lighter one", () => {
  const list = [c(0.1, 0, 0), c(0.5, 0.4, 0.3)];
  assert.equal(pickAccent(list, { minLuma: 0.2 }), 1);
});

test("pickAccent: empty or invalid input -> -1", () => {
  assert.equal(pickAccent([], { minLuma: 0.2 }), -1);
  assert.equal(pickAccent(null, { minLuma: 0.2 }), -1);
  assert.equal(pickAccent([null, c(NaN, 0, 0)], { minLuma: 0.2 }), -1);
});
