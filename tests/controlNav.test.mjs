import { test } from "node:test";
import assert from "node:assert/strict";
import { initialView } from "../shell/logic/controlNav.mjs";

test("initialView opens the control center at the root", () => {
  assert.equal(initialView(), "root");
});
