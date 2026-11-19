import { test } from "node:test";
import assert from "node:assert/strict";
import { enrolledFingers } from "../shell/logic/fingerprint.mjs";

const header = "found 1 devices\n" +
  "Device at /net/reactivated/Fprint/Device/0\n" +
  "Using device /net/reactivated/Fprint/Device/0\n";

test("the registered fingers come from fprintd-list", () => {
  assert.deepEqual(
    enrolledFingers(
      header +
        "Fingerprints for user me on Synaptics Sensors (press):\n" +
        " - #0: right-index-finger\n",
    ),
    ["right-index-finger"],
  );
  assert.deepEqual(
    enrolledFingers(
      header +
        "Fingerprints for user me on Synaptics Sensors (press):\n" +
        " - #0: left-thumb\n" +
        " - #1: right-middle-finger\n",
    ),
    ["left-thumb", "right-middle-finger"],
  );
});

test("a user without fingerprints has none registered", () => {
  assert.deepEqual(
    enrolledFingers(
      header + "User me has no fingerprints enrolled for Synaptics Sensors.\n",
    ),
    [],
  );
});
