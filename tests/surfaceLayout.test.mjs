import { test } from "node:test";
import assert from "node:assert/strict";
import { layoutFor } from "../shell/logic/surfaceLayout.mjs";

const tokens = {
  idleHeight: 32,
  cornerWidth: 200,
  osdWidth: 48,
  gap: 8,
  centerMaxWidth: 600,
  centerMaxWidthByMonitor: { "DP-2": 500 },
};

const topRow = (l) => [l.tl, l.c, l.tr];

test("wide screen: centre gets its token width, centred between the corners", () => {
  const l = layoutFor(1920, "DP-1", tokens);
  assert.deepEqual(l.tl, { x: 0, width: 200, height: 32 });
  assert.deepEqual(l.c, { x: 660, width: 600, height: 32 });
  assert.deepEqual(l.tr, { x: 1720, width: 200, height: 32 });
});

test("narrow screen: centre width is capped to keep a gap to both corners", () => {
  const l = layoutFor(800, "DP-1", tokens);
  assert.equal(l.c.width, 384);
  assert.equal(l.c.x - (l.tl.x + l.tl.width), 8);
  assert.equal(l.tr.x - (l.c.x + l.c.width), 8);
});

test("per-monitor max width overrides the default", () => {
  assert.equal(layoutFor(1920, "DP-2", tokens).c.width, 500);
  assert.equal(layoutFor(1920, "DP-1", tokens).c.width, 600);
});

test("a per-monitor max still cannot exceed the available space", () => {
  const big = { ...tokens, centerMaxWidthByMonitor: { "DP-2": 5000 } };
  assert.equal(layoutFor(800, "DP-2", big).c.width, 384);
});

test("slots never overlap on any screen width", () => {
  for (const w of [100, 300, 416, 417, 800, 1366, 1920, 3840]) {
    const row = topRow(layoutFor(w, "DP-1", tokens));
    for (let i = 1; i < row.length; i++) {
      assert.ok(
        row[i - 1].x + row[i - 1].width <= row[i].x,
        `overlap at ${w}: ${JSON.stringify(row)}`,
      );
    }
    assert.ok(row[2].x + row[2].width <= w, `tr leaves the screen at ${w}`);
  }
});

test("tiny screen: corners shrink to half and the centre collapses to zero", () => {
  const l = layoutFor(300, "DP-1", tokens);
  assert.deepEqual(l.tl, { x: 0, width: 150, height: 32 });
  assert.deepEqual(l.tr, { x: 150, width: 150, height: 32 });
  assert.equal(l.c.width, 0);
});

test("edge strips: bl on the left edge, vr (OSD) on the right edge", () => {
  const l = layoutFor(1920, "DP-1", tokens);
  assert.deepEqual(l.bl, { x: 0, width: 200, height: 32 });
  assert.deepEqual(l.vr, { x: 1872, width: 48, height: 32 });
});
