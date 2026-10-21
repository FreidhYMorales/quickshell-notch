import { test } from "node:test";
import assert from "node:assert/strict";
import {
  expandedWidth,
  idleBase,
  idleWidth,
  shapeFor,
  sideExtent,
} from "../shell/logic/centerLayout.mjs";

// Spec table: base 260, side 60.
for (
  const [layer, total] of [
    ["none", 260],
    ["charging", 380],
    ["plugged", 380],
    ["full", 380],
    ["low", 380],
  ]
) {
  test(`idleWidth layer ${layer} -> ${total}`, () => {
    assert.equal(idleWidth({ base: 260, side: 60, layer, max: 600 }), total);
  });
}

test("idleWidth is capped at max", () => {
  assert.equal(
    idleWidth({ base: 260, side: 60, layer: "charging", max: 300 }),
    300,
  );
});

// Spec table for expandedWidth.
for (
  const [hasPlayer, max, expected] of [
    [true, 600, 560],
    [false, 600, 300],
    [true, 400, 400],
    [false, 250, 250],
  ]
) {
  test(`expandedWidth player=${hasPlayer} max=${max} -> ${expected}`, () => {
    assert.equal(
      expandedWidth({ hasPlayer, full: 560, clockOnly: 300, max }),
      expected,
    );
  });
}

const W = { idle: 380, expanded: 560 };
const H = { idle: 32, expanded: 180 };

test("shapeFor picks idle or expanded size by mode", () => {
  assert.deepEqual(shapeFor("idle", W, H), { width: 380, height: 32 });
  assert.deepEqual(shapeFor("expanded", W, H), { width: 560, height: 180 });
});

test("shapeFor treats any non-expanded mode as idle", () => {
  assert.deepEqual(shapeFor("hover", W, H), { width: 380, height: 32 });
});

// Content-driven widths: no fixed idle width, no gap between the row and a
// side layer.
test("idleBase is the row plus symmetric padding plus both ears", () => {
  assert.equal(idleBase({ row: 180, pad: 16, ear: 12 }), 236);
  assert.equal(idleBase({ row: 0, pad: 0, ear: 12 }), 24);
});

test("sideExtent is the wider item plus the gap to the row", () => {
  assert.equal(sideExtent({ left: 14, right: 30, gap: 8 }), 38);
  assert.equal(sideExtent({ left: 40, right: 12, gap: 8 }), 48);
});

test("sideExtent ignores an absent (zero width) item", () => {
  assert.equal(sideExtent({ left: 22, right: 0, gap: 8 }), 30);
});

test("content-driven idle width: both sides grow by the same amount", () => {
  const base = idleBase({ row: 180, pad: 16, ear: 12 });
  const side = sideExtent({ left: 14, right: 30, gap: 8 });
  assert.equal(idleWidth({ base, side, layer: "none", max: 600 }), 236);
  assert.equal(idleWidth({ base, side, layer: "charging", max: 600 }), 312);
});
