import { test } from "node:test";
import assert from "node:assert/strict";
import { cornerShape } from "../shell/logic/cornerLayout.mjs";

const base = {
  contentWidth: 100,
  contentHeight: 32,
  pad: 10,
  ear: 12,
  maxWidth: 400,
  maxHeight: 60,
};
const rows = [
  ["content plus padding on both sides and one ear", {}, {
    width: 100 + 2 * 10 + 12,
    height: 32 + 12,
  }],
  ["the ear is added to the height, not swallowed", { contentHeight: 20 }, {
    width: 132,
    height: 32,
  }],
  ["width is capped to maxWidth", { contentWidth: 900 }, {
    width: 400,
    height: 44,
  }],
  ["height is capped to maxHeight", { contentHeight: 200 }, {
    width: 132,
    height: 60,
  }],
  ["empty content leaves padding and ears only", { contentWidth: 0 }, {
    width: 32,
    height: 44,
  }],
  ["zero ear and pad give the bare content", { ear: 0, pad: 0 }, {
    width: 100,
    height: 32,
  }],
  ["negative inputs are floored at zero", {
    contentWidth: -5,
    contentHeight: -5,
    pad: -1,
    ear: -1,
  }, { width: 0, height: 0 }],
  ["a negative max collapses to zero", { maxWidth: -1, maxHeight: -1 }, {
    width: 0,
    height: 0,
  }],
];
for (const [name, over, want] of rows) {
  test(`cornerShape: ${name}`, () => {
    assert.deepEqual(cornerShape(Object.assign({}, base, over)), want);
  });
}
