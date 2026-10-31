import { test } from "node:test";
import assert from "node:assert/strict";
import {
  back,
  closeOnLeave,
  initialView,
  openSubpage,
} from "../shell/logic/controlNav.mjs";

test("initialView opens the control center at the root", () => {
  assert.equal(initialView(), "root");
});

test("openSubpage shows the notifications view and back returns to the root", () => {
  assert.equal(openSubpage(), "notifications");
  assert.equal(back(), "root");
});

test("closeOnLeave collapses at once on the root and waits on a subpage", () => {
  assert.equal(closeOnLeave("root"), "now");
  assert.equal(closeOnLeave("notifications"), "wait");
});
