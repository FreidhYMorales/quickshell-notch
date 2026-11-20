import { test } from "node:test";
import assert from "node:assert/strict";
import { shiftOffset } from "../shell/logic/pixelShift.mjs";

// Spec: home, right, right+down, down, back home.
for (
  const [step, expected] of [
    [0, { x: 0, y: 0 }],
    [1, { x: 1, y: 0 }],
    [2, { x: 1, y: 1 }],
    [3, { x: 0, y: 1 }],
    [4, { x: 0, y: 0 }],
    [4001, { x: 1, y: 0 }],
  ]
) {
  test(`shiftOffset(${step}) is ${expected.x},${expected.y}`, () => {
    assert.deepEqual(shiftOffset(step), expected);
  });
}

test("shiftOffset never leaves one pixel from home", () => {
  const offsets = [];
  for (let step = 0; step < 50; step++) offsets.push(shiftOffset(step));
  assert.equal(offsets.length, 50);
  for (const { x, y } of offsets) {
    assert.ok(x === 0 || x === 1, `x ${x}`);
    assert.ok(y === 0 || y === 1, `y ${y}`);
  }
});
