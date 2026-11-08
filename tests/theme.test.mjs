import { test } from "node:test";
import assert from "node:assert/strict";
import { MODES } from "../shell/logic/theme.mjs";

test("theme modes are the nine matugen scheme types in display order", () => {
  assert.deepEqual(MODES, [
    "scheme-tonal-spot",
    "scheme-monochrome",
    "scheme-vibrant",
    "scheme-expressive",
    "scheme-fidelity",
    "scheme-content",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-fruit-salad",
  ]);
});
