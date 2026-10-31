import { test } from "node:test";
import assert from "node:assert/strict";
import { back, initialView, openSubpage } from "../shell/logic/controlNav.mjs";

test("initialView opens the control center at the root", () => {
  assert.equal(initialView(), "root");
});

test("openSubpage shows the notifications view and back returns to the root", () => {
  assert.equal(openSubpage(), "notifications");
  assert.equal(back(), "root");
});
