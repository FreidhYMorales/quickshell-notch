import { test } from "node:test";
import assert from "node:assert/strict";
import { bindsFromJson, filterKeybinds } from "../shell/logic/keybinds.mjs";

const registry = (binds) => JSON.stringify(binds);

test("binds map to a key label and keep only described ones", () => {
  const json = registry([
    { modmask: 64, key: "RETURN", description: "Open Terminal" },
    { modmask: 12, key: "F", description: "Toggle Fullscreen Window" },
    { modmask: 64, key: "1", description: "" },
    { modmask: 0, key: "XF86AudioMute", description: "Mute" },
  ]);
  assert.deepEqual(bindsFromJson(json), {
    available: true,
    rows: [
      { keys: "Super + RETURN", description: "Open Terminal" },
      { keys: "Ctrl + Alt + F", description: "Toggle Fullscreen Window" },
      { keys: "XF86AudioMute", description: "Mute" },
    ],
  });
});

test("an unreadable registry is reported instead of thrown", () => {
  assert.deepEqual(bindsFromJson("hyprctl: compositor not running"), {
    available: false,
    rows: [],
  });
  assert.deepEqual(bindsFromJson('{"error":"unknown request"}'), {
    available: false,
    rows: [],
  });
});

test("the query filters rows by key label or description", () => {
  const rows = [
    { keys: "Super + RETURN", description: "Open Terminal" },
    { keys: "Super + B", description: "Open or focus Browser" },
    { keys: "XF86AudioMute", description: "Mute" },
  ];
  assert.deepEqual(filterKeybinds(rows, "browser"), [rows[1]]);
  assert.deepEqual(filterKeybinds(rows, "super + return"), [rows[0]]);
  assert.deepEqual(filterKeybinds(rows, ""), rows);
  assert.deepEqual(filterKeybinds(rows, "xyz"), []);
});
