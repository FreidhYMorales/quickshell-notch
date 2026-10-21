import { test } from "node:test";
import assert from "node:assert/strict";
import {
  cornerPath,
  earCubic,
  notchPath,
} from "../shell/logic/earGeometry.mjs";

const right = { x: 1, y: 0 };
const down = { x: 0, y: 1 };
const left = { x: -1, y: 0 };
const up = { x: 0, y: -1 };

test("earCubic: leaving endpoint is extended by k, tangents follow the edges", () => {
  assert.deepEqual(earCubic(100, 0, 10, 6, 13, right, down, false), {
    startX: 90,
    startY: 0,
    endX: 100,
    endY: 16,
    c1x: 103,
    c1y: 0,
    c2x: 100,
    c2y: 3,
  });
});

test("earCubic: entering endpoint is extended when extendEntering is set", () => {
  assert.deepEqual(earCubic(0, 0, 10, 6, 13, up, right, true), {
    startX: 0,
    startY: 16,
    endX: 10,
    endY: 0,
    c1x: 0,
    c1y: 3,
    c2x: -3,
    c2y: 0,
  });
});

test("earCubic: k = 0 gives plain radius endpoints on both sides", () => {
  const c = earCubic(0, 40, 10, 0, 13, left, up, false);
  assert.deepEqual([c.startX, c.startY, c.endX, c.endY], [10, 40, 0, 30]);
});

test("notchPath: concave top ears, convex bottom corners", () => {
  assert.equal(
    notchPath(100, 40, 10, 8),
    "M 10 0 L 90 0 C 103 0 100 3 100 16 L 100 32 A 8 8 0 0 1 92 40 " +
      "L 8 40 A 8 8 0 0 1 0 32 L 0 16 C 0 3 -3 0 10 0 Z",
  );
});

test("notchPath: radii are clamped while the height grows from zero", () => {
  const p = notchPath(100, 4, 10, 8);
  assert.equal(p, notchPath(100, 4, 4, 4));
  assert.ok(!p.includes("NaN"));
  assert.notEqual(p, notchPath(100, 40, 10, 8));
});

test("cornerPath topLeft: square anchor, ears at TR and BL, round BR", () => {
  assert.equal(
    cornerPath(100, 40, "topLeft", 10, 8),
    "M 0 0 L 90 0 C 103 0 100 3 100 16 L 100 32 A 8 8 0 0 1 92 40 " +
      "L 16 40 C 3 40 0 43 0 30 L 0 0 Z",
  );
});

test("cornerPath topRight: square at TR, ears at TL and BR, round BL", () => {
  assert.equal(
    cornerPath(100, 40, "topRight", 10, 8),
    "M 10 0 L 100 0 L 100 30 C 100 43 97 40 84 40 L 8 40 " +
      "A 8 8 0 0 1 0 32 L 0 16 C 0 3 -3 0 10 0 Z",
  );
});

test("cornerPath bottomLeft: square at BL, ears at TL and BR, round TR", () => {
  assert.equal(
    cornerPath(100, 40, "bottomLeft", 10, 8),
    "M 16 0 L 92 0 A 8 8 0 0 1 100 8 L 100 24 C 100 37 103 40 90 40 " +
      "L 0 40 L 0 10 C 0 -3 3 0 16 0 Z",
  );
});

test("cornerPath bottomRight: square at BR, ears at TR and BL, round TL", () => {
  assert.equal(
    cornerPath(100, 40, "bottomRight", 10, 8),
    "M 8 0 L 84 0 C 97 0 100 -3 100 10 L 100 40 L 10 40 " +
      "C -3 40 0 37 0 24 L 0 8 A 8 8 0 0 1 8 0 Z",
  );
});

test("cornerPath: unknown anchor returns null", () => {
  assert.equal(cornerPath(100, 40, "middle", 10, 8), null);
});
