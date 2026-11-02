import { test } from "node:test";
import assert from "node:assert/strict";
import { appInitial } from "../shell/logic/workspaceStrip.mjs";

test("tray fallback uses the first letter of the full app title", () => {
  assert.equal(appInitial("org.vesktop.Vesktop", "?", true), "O");
  assert.equal(appInitial("Steam", "?", true), "S");
});
