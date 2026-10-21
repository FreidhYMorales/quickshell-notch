import { test } from "node:test";
import assert from "node:assert/strict";
import { sideLayer, sideWidth } from "../shell/logic/sideLayer.mjs";
import { idleWidth } from "../shell/logic/centerLayout.mjs";

// Spec table: battery layer, playing, result.
for (
  const [battery, playing, expected] of [
    ["none", false, "none"],
    ["none", true, "media"],
    ["low", false, "low"],
    ["low", true, "low"],
    ["charging", false, "charging"],
    ["charging", true, "media"],
    ["plugged", false, "plugged"],
    ["plugged", true, "media"],
    ["full", false, "full"],
    ["full", true, "media"],
  ]
) {
  test(`sideLayer ${battery} playing=${playing} -> ${expected}`, () => {
    assert.equal(sideLayer(battery, playing), expected);
  });
}

test("pause releases media back to the battery layer", () => {
  assert.equal(sideLayer("charging", true), "media");
  assert.equal(sideLayer("charging", false), "charging");
});

const sides = { battery: 60, media: 80 };
for (
  const [layer, expected] of [
    ["none", 0],
    ["charging", 60],
    ["plugged", 60],
    ["low", 60],
    ["full", 60],
    ["media", 80],
  ]
) {
  test(`sideWidth ${layer} -> ${expected}`, () => {
    assert.equal(sideWidth(layer, sides), expected);
  });
}

test("composes with idleWidth: media grows symmetrically and is capped", () => {
  const side = sideWidth("media", sides);
  assert.equal(idleWidth({ base: 260, side, layer: "media", max: 600 }), 420);
  assert.equal(idleWidth({ base: 260, side, layer: "media", max: 300 }), 300);
  const none = sideWidth("none", sides);
  assert.equal(
    idleWidth({ base: 260, side: none, layer: "none", max: 600 }),
    260,
  );
});
