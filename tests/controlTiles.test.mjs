import { test } from "node:test";
import assert from "node:assert/strict";
import { tilesFor } from "../shell/logic/controlTiles.mjs";

test("tilesFor: every backend present gives WiFi, Bluetooth and DND", () => {
  assert.deepEqual(tilesFor({ wifi: true, bt: false, dnd: true }), [
    { id: "wifi", on: true },
    { id: "bt", on: false },
    { id: "dnd", on: true },
  ]);
});

test("tilesFor: no WiFi radio hides the WiFi tile", () => {
  assert.deepEqual(tilesFor({ wifi: null, bt: true, dnd: false }), [
    { id: "bt", on: true },
    { id: "dnd", on: false },
  ]);
});

test("tilesFor: no Bluetooth adapter hides the Bluetooth tile", () => {
  assert.deepEqual(tilesFor({ wifi: false, bt: null, dnd: false }), [
    { id: "wifi", on: false },
    { id: "dnd", on: false },
  ]);
});
