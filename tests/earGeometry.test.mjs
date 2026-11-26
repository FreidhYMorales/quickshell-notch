import { test } from "node:test";
import assert from "node:assert/strict";
import {
  cornerOutlinePath,
  cornerPath,
  notchOutlinePath,
  notchPath,
} from "../shell/logic/earGeometry.mjs";

// Concave ears: the edge touching the screen flares OUTWARD past the body and
// curves into the body side (quarter circle centred on the screen edge).
// The first revision pinned the inverted shape (convex corners cutting the
// box); these expectations replace it.

const KAPPA = 0.5523;

/** Parses "M x y L x y C ... A r r 0 0 s x y Z" into command objects. */
function parse(path) {
  const cmds = [];
  const re = /([MLCAZ])([^MLCAZ]*)/g;
  let m;
  while ((m = re.exec(path)) !== null) {
    const nums = m[2].trim() === "" ? [] : m[2].trim().split(/\s+/).map(Number);
    cmds.push({ op: m[1], n: nums, end: nums.slice(-2) });
  }
  return cmds;
}

const near = (a, b, eps = 0.01) =>
  assert.ok(Math.abs(a - b) <= eps, `${a} != ${b}`);

/** Point of a cubic at t. p = [x0,y0,x1,y1,x2,y2,x3,y3]. */
function bezier(p, t) {
  const u = 1 - t;
  const f = (i) =>
    u * u * u * p[i] + 3 * u * u * t * p[i + 2] + 3 * u * t * t * p[i + 4] +
    t * t * t * p[i + 6];
  return [f(0), f(1)];
}

/** Cubics of a path as full 8-number arrays (start taken from previous end). */
function cubics(path) {
  const out = [];
  let cur = null;
  for (const c of parse(path)) {
    if (c.op === "C") out.push([cur[0], cur[1], ...c.n]);
    if (c.op !== "Z") cur = c.end;
  }
  return out;
}

test("notchPath: exact concave path, top edge full width, sides inset by er", () => {
  assert.equal(
    notchPath(100, 40, 10, 8),
    "M 0 0 L 100 0 C 94.477 0 90 4.477 90 10 L 90 32 A 8 8 0 0 1 82 40 " +
      "L 18 40 A 8 8 0 0 1 10 32 L 10 10 C 10 4.477 5.523 0 0 0 Z",
  );
});

test("notchOutlinePath is one continuous exposed contour through both ears", () => {
  assert.equal(
    notchOutlinePath(100, 40, 10, 8),
    "M 0 0 C 5.523 0 10 4.477 10 10 L 10 32 A 7 7 0 0 0 17 39 L 83 39 A 7 7 0 0 0 90 32 L 90 10 C 90 4.477 94.477 0 100 0",
  );
});

test("notchOutlinePath insets the lower stroke to avoid clipping at the bounds", () => {
  assert.equal(
    notchOutlinePath(100, 40, 10, 8),
    "M 0 0 C 5.523 0 10 4.477 10 10 L 10 32 A 7 7 0 0 0 17 39 L 83 39 A 7 7 0 0 0 90 32 L 90 10 C 90 4.477 94.477 0 100 0",
  );
});

test("notchOutlinePath clamps ear and corner radii", () => {
  assert.equal(
    notchOutlinePath(12, 8, 99, 99),
    "M 0 0 C 3.314 0 6 2.686 6 6 L 6 8 L 6 8 L 6 6 C 6 2.686 8.686 0 12 0",
  );
});

test("notchPath: second sizing keeps the same structure (triangulation)", () => {
  assert.equal(
    notchPath(260, 32, 10, 10),
    "M 0 0 L 260 0 C 254.477 0 250 4.477 250 10 L 250 22 A 10 10 0 0 1 240 32 " +
      "L 20 32 A 10 10 0 0 1 10 22 L 10 10 C 10 4.477 5.523 0 0 0 Z",
  );
});

test("notchPath: ear tangents are horizontal at the top and vertical at the body", () => {
  const [right, left] = cubics(notchPath(100, 40, 10, 8));
  // right ear: (100,0) -> (90,10); c1 on y=0 (horizontal), c2 on x=90 (vertical)
  assert.equal(right[1], 0);
  assert.equal(right[3], 0);
  assert.equal(right[4], 90);
  assert.equal(right[6], 90);
  // left ear: (10,10) -> (0,0); c1 on x=10 (vertical), c2 on y=0 (horizontal)
  assert.equal(left[0], 10);
  assert.equal(left[2], 10);
  assert.equal(left[5], 0);
  assert.equal(left[7], 0);
  near(right[2], 100 - KAPPA * 10, 0.001);
  near(left[4], KAPPA * 10, 0.001);
});

test("notchPath: ear is concave (curve bows toward the flare, on the circle)", () => {
  const [, left] = cubics(notchPath(100, 40, 10, 8));
  const [x, y] = bezier(left, 0.5);
  // closer to the top-left corner side than the chord midpoint on the y axis,
  // and on the quarter circle centred at (0, er)
  assert.ok(y < 5, `y=${y} should be above the chord midpoint 5`);
  near(Math.hypot(x - 0, y - 10), 10, 0.05);
  const [right] = cubics(notchPath(100, 40, 10, 8));
  const [rx, ry] = bezier(right, 0.5);
  assert.ok(ry < 5);
  near(Math.hypot(rx - 100, ry - 10), 10, 0.05);
});

test("notchPath: clamps while the height grows from zero", () => {
  assert.equal(notchPath(100, 4, 10, 8), notchPath(100, 4, 4, 0));
  assert.equal(notchPath(100, 15, 10, 8), notchPath(100, 15, 10, 5));
  assert.notEqual(notchPath(100, 4, 10, 8), notchPath(100, 40, 10, 8));
  for (const h of [0, 1, 4, 9, 18, 40]) {
    const p = notchPath(100, h, 10, 8);
    assert.ok(!/NaN|-\d/.test(p), `h=${h}: ${p}`);
  }
});

test("notchPath: clamps on narrow widths (2*er + 2*cr <= w)", () => {
  const p = notchPath(20, 40, 10, 8);
  assert.equal(p, notchPath(20, 40, 10, 0));
  assert.ok(!/NaN|-\d/.test(p));
});

// cornerPath: topLeft is hand-derived; the others mirror it.
test("cornerPath topLeft: square anchor, edges flare to far corners", () => {
  assert.equal(
    cornerPath(100, 40, "topLeft", 10, 8),
    "M 0 0 L 100 0 C 94.477 0 90 4.477 90 10 L 90 22 A 8 8 0 0 1 82 30 " +
      "L 10 30 C 4.477 30 0 34.477 0 40 L 0 0 Z",
  );
});

test("cornerPath topRight: mirrored on x", () => {
  assert.equal(
    cornerPath(100, 40, "topRight", 10, 8),
    "M 100 0 L 0 0 C 5.523 0 10 4.477 10 10 L 10 22 A 8 8 0 0 0 18 30 " +
      "L 90 30 C 95.523 30 100 34.477 100 40 L 100 0 Z",
  );
});

test("cornerOutlinePath draws top ear and lower contour as one continuous path", () => {
  assert.equal(
    cornerOutlinePath(100, 40, "topLeft", 10, 8),
    "M 100 0 C 94.477 0 90 4.477 90 10 L 90 22 A 8 8 0 0 1 82 30 L 10 30 C 4.477 30 0 34.477 0 40",
  );
  assert.equal(
    cornerOutlinePath(100, 40, "topRight", 10, 8),
    "M 0 0 C 5.523 0 10 4.477 10 10 L 10 22 A 8 8 0 0 0 18 30 L 90 30 C 95.523 30 100 34.477 100 40",
  );
  assert.equal(cornerOutlinePath(100, 40, "bottomLeft", 10, 8), null);
});

test("cornerPath bottomLeft: mirrored on y", () => {
  assert.equal(
    cornerPath(100, 40, "bottomLeft", 10, 8),
    "M 0 40 L 100 40 C 94.477 40 90 35.523 90 30 L 90 18 A 8 8 0 0 0 82 10 " +
      "L 10 10 C 4.477 10 0 5.523 0 0 L 0 40 Z",
  );
});

test("cornerPath bottomRight: mirrored on both axes", () => {
  assert.equal(
    cornerPath(100, 40, "bottomRight", 10, 8),
    "M 100 40 L 0 40 C 5.523 40 10 35.523 10 30 L 10 18 A 8 8 0 0 1 18 10 " +
      "L 90 10 C 95.523 10 100 5.523 100 0 L 100 40 Z",
  );
});

test("cornerPath: every anchor touches both of its screen edges at full length", () => {
  const corners = {
    topLeft: [0, 0],
    topRight: [100, 0],
    bottomLeft: [0, 40],
    bottomRight: [100, 40],
  };
  for (const [anchor, [ax, ay]] of Object.entries(corners)) {
    const cmds = parse(cornerPath(100, 40, anchor, 10, 8));
    assert.deepEqual(cmds[0].end, [ax, ay], anchor);
    const pts = cmds.filter((c) => c.op !== "Z").map((c) => c.end);
    // the far corners along both edges are reached (edges flare to full length)
    const fx = ax === 0 ? 100 : 0;
    const fy = ay === 0 ? 40 : 0;
    assert.ok(pts.some(([x, y]) => x === fx && y === ay), `${anchor} x edge`);
    assert.ok(pts.some(([x, y]) => x === ax && y === fy), `${anchor} y edge`);
  }
});

test("cornerPath: clamps small sizes without NaN or negatives", () => {
  for (const anchor of ["topLeft", "topRight", "bottomLeft", "bottomRight"]) {
    for (const [w, h] of [[100, 0], [100, 4], [100, 15], [10, 40], [0, 0]]) {
      const p = cornerPath(w, h, anchor, 10, 8);
      assert.ok(!/NaN|-\d/.test(p), `${anchor} ${w}x${h}: ${p}`);
    }
  }
});

test("cornerPath: unknown anchor returns null", () => {
  assert.equal(cornerPath(100, 40, "middle", 10, 8), null);
});
