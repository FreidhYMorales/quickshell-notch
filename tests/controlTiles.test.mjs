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

test("tilesFor: the profile and caffeine tiles come after DND", () => {
  const ids = tilesFor({
    wifi: true,
    bt: false,
    dnd: true,
    profile: "performance",
    caffeine: true,
  }).map((tile) => tile.id);
  assert.deepEqual(ids, ["wifi", "bt", "dnd", "profile", "caffeine"]);
});

test("tilesFor: the profile tile is lit only when the profile is not balanced", () => {
  const profileOn = (profile) =>
    tilesFor({
      wifi: null,
      bt: null,
      dnd: null,
      profile: profile,
      caffeine: null,
    }).find((tile) => tile.id === "profile").on;
  assert.equal(profileOn("balanced"), false);
  assert.equal(profileOn("performance"), true);
});

test("tilesFor: no power profile backend hides the profile tile", () => {
  assert.deepEqual(
    tilesFor({
      wifi: true,
      bt: false,
      dnd: true,
      profile: null,
      caffeine: false,
    }),
    [
      { id: "wifi", on: true },
      { id: "bt", on: false },
      { id: "dnd", on: true },
      { id: "caffeine", on: false },
    ],
  );
});

test("tilesFor: the caffeine tile follows the flag", () => {
  const caffeineOn = (value) =>
    tilesFor({
      wifi: null,
      bt: null,
      dnd: null,
      profile: null,
      caffeine: value,
    }).find((tile) => tile.id === "caffeine").on;
  assert.equal(caffeineOn(true), true);
  assert.equal(caffeineOn(false), false);
});
