import { test } from "node:test";
import assert from "node:assert/strict";
import {
  enrolledFingers,
  enrollResult,
  fingerLayout,
  fingerMatchFromSignal,
  freeFingers,
} from "../shell/logic/fingerprint.mjs";

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

// Each fprintd-enroll result: a counted touch, a hint key the view shows,
// or the end of the enrollment ("completed" or "failed").
test("a passed stage counts one touch and asks for the next", () => {
  assert.deepEqual(enrollResult("Enroll result: enroll-stage-passed"), {
    touch: true,
    hint: "again",
    end: "",
  });
});

test("a completed enrollment ends it successfully", () => {
  assert.deepEqual(enrollResult("Enroll result: enroll-completed"), {
    touch: false,
    hint: "",
    end: "completed",
  });
});

test("a failed, duplicate or disconnected enrollment ends it as failed", () => {
  for (
    const status of ["enroll-failed", "enroll-duplicate", "enroll-disconnected"]
  ) {
    assert.deepEqual(enrollResult("Enroll result: " + status), {
      touch: false,
      hint: "",
      end: "failed",
    });
  }
});

test("a bad touch gives its own hint and keeps enrolling", () => {
  assert.deepEqual(enrollResult("Enroll result: enroll-retry-scan"), {
    touch: false,
    hint: "retry-scan",
    end: "",
  });
  assert.deepEqual(enrollResult("Enroll result: enroll-finger-not-centered"), {
    touch: false,
    hint: "finger-not-centered",
    end: "",
  });
});

test("lines without an enroll result change nothing", () => {
  assert.equal(
    enrollResult("Using device /net/reactivated/Fprint/Device/0"),
    null,
  );
  assert.deepEqual(enrollResult("Enroll result: enroll-stage-passed"), {
    touch: true,
    hint: "again",
    end: "",
  });
});

const allFingers = [
  "left-thumb",
  "left-index-finger",
  "left-middle-finger",
  "left-ring-finger",
  "left-little-finger",
  "right-thumb",
  "right-index-finger",
  "right-middle-finger",
  "right-ring-finger",
  "right-little-finger",
];

test("every finger is free while none is registered", () => {
  assert.deepEqual(freeFingers([]), allFingers);
});

test("registered fingers are not offered again", () => {
  assert.deepEqual(freeFingers(["right-index-finger", "left-thumb"]), [
    "left-index-finger",
    "left-middle-finger",
    "left-ring-finger",
    "left-little-finger",
    "right-thumb",
    "right-middle-finger",
    "right-ring-finger",
    "right-little-finger",
  ]);
  assert.deepEqual(freeFingers(allFingers), []);
});

test("fingerLayout arranges all ten prints like two facing hands", () => {
  const layout = fingerLayout();
  assert.deepEqual(layout.map((entry) => entry.name), [
    "left-little-finger",
    "left-ring-finger",
    "left-middle-finger",
    "left-index-finger",
    "left-thumb",
    "right-thumb",
    "right-index-finger",
    "right-middle-finger",
    "right-ring-finger",
    "right-little-finger",
  ]);
  assert.ok(layout[0].y > layout[2].y);
  assert.ok(layout[4].y > layout[3].y);
  assert.ok(layout[5].y > layout[6].y);
  assert.ok(layout[9].y > layout[7].y);
  assert.ok(layout.every((entry) => entry.x >= 0 && entry.x <= 1));
});

test("fingerMatchFromSignal extracts only a known matched finger", () => {
  assert.equal(
    fingerMatchFromSignal(
      "/net/reactivated/Fprint/Device/0: net.reactivated.Fprint.Device.VerifyFingerMatched ('right-index-finger',)",
    ),
    "right-index-finger",
  );
  assert.equal(
    fingerMatchFromSignal(
      "/net/reactivated/Fprint/Device/0: net.reactivated.Fprint.Device.VerifyStatus ('verify-match', true)",
    ),
    null,
  );
  assert.equal(
    fingerMatchFromSignal(
      "/net/reactivated/Fprint/Device/0: net.reactivated.Fprint.Device.VerifyFingerMatched ('unknown-finger',)",
    ),
    null,
  );
});
