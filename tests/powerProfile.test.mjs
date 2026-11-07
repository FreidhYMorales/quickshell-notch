import { test } from "node:test";
import assert from "node:assert/strict";
import { cycleProfile } from "../shell/logic/powerProfile.mjs";

test("cycleProfile: walks performance, balanced and power-saver in a loop", () => {
  assert.equal(cycleProfile("performance"), "balanced");
  assert.equal(cycleProfile("balanced"), "power-saver");
  assert.equal(cycleProfile("power-saver"), "performance");
});
