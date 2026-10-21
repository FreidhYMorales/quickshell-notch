import { test } from "node:test";
import assert from "node:assert/strict";
import { layoutFor } from "../shell/logic/surfaceLayout.mjs";

const tokens = {
  idleHeight: 32,
  cornerWidth: 200,
  osdWidth: 220,
  gap: 8,
  centerMaxWidth: 600,
  centerMaxWidthByMonitor: { "DP-2": 500 },
};

const topRow = (l) => [l.tl, l.bl, l.c, l.vr, l.tr];

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
    assert.ok(row[4].x + row[4].width <= w, `tr leaves the screen at ${w}`);
  }
});

test("tiny screen: corners shrink to half and the centre collapses to zero", () => {
  const l = layoutFor(300, "DP-1", tokens);
  assert.deepEqual(l.tl, { x: 0, width: 150, height: 32 });
  assert.deepEqual(l.tr, { x: 150, width: 150, height: 32 });
  assert.equal(l.c.width, 0);
});

test("OSD slots sit on the top row between each corner and the centre", () => {
  const l = layoutFor(1920, "DP-1", tokens);
  // free space left of the centre: 200..660 -> OSD centred in it
  assert.deepEqual(l.bl, { x: 320, width: 220, height: 32 });
  assert.deepEqual(l.vr, { x: 1380, width: 220, height: 32 });
});

test("OSD shrinks before the centre does, keeping a gap on both sides", () => {
  const l = layoutFor(1366, "DP-1", tokens);
  assert.equal(l.c.width, 600);
  assert.equal(l.bl.width, 167);
  assert.equal(l.bl.x - (l.tl.x + l.tl.width), 8);
  assert.equal(l.c.x - (l.bl.x + l.bl.width), 8);
  assert.equal(l.vr.width, 167);
});

test("OSD collapses to zero when there is no room beside the centre", () => {
  const l = layoutFor(800, "DP-1", tokens);
  assert.equal(l.bl.width, 0);
  assert.equal(l.vr.width, 0);
});

test("expandedHeight sets the centre slot height only", () => {
  const l = layoutFor(1920, "DP-1", { ...tokens, expandedHeight: 180 });
  assert.equal(l.c.height, 180);
  assert.equal(l.tl.height, 32);
  assert.equal(l.vr.height, 32);
});

test("without expandedHeight the centre keeps the idle height", () => {
  assert.equal(layoutFor(1920, "DP-1", tokens).c.height, 32);
});

test("cornerHeight sets the TL slot height only", () => {
  const l = layoutFor(1920, "DP-1", { ...tokens, cornerHeight: 44 });
  assert.equal(l.tl.height, 44);
  assert.equal(l.tr.height, 32);
  assert.equal(l.bl.height, 32);
  assert.equal(l.c.height, 32);
});

test("osdHeight sets the BL and VR slot heights only", () => {
  const l = layoutFor(1920, "DP-1", { ...tokens, osdHeight: 36 });
  assert.equal(l.bl.height, 36);
  assert.equal(l.vr.height, 36);
  assert.equal(l.tl.height, 32);
  assert.equal(l.tr.height, 32);
});

test("without cornerHeight/osdHeight every slot keeps the idle height", () => {
  const l = layoutFor(1920, "DP-1", tokens);
  assert.deepEqual(
    [l.tl.height, l.bl.height, l.vr.height, l.tr.height],
    [32, 32, 32, 32],
  );
});

test("heights never change x or width of any slot", () => {
  const a = layoutFor(1366, "DP-1", tokens);
  const b = layoutFor(1366, "DP-1", {
    ...tokens,
    cornerHeight: 44,
    osdHeight: 36,
  });
  for (const k of ["tl", "bl", "c", "vr", "tr"]) {
    assert.equal(b[k].x, a[k].x, k);
    assert.equal(b[k].width, a[k].width, k);
  }
});
