import { test } from "node:test";
import assert from "node:assert/strict";
import { bindsFromJson } from "../shell/logic/keybinds.mjs";

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
