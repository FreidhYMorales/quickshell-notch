import { test } from "node:test";
import assert from "node:assert/strict";
import { initialReveal, stepReveal } from "../shell/logic/reveal.mjs";
import { stripFor } from "../shell/logic/workspaceStrip.mjs";

test("right-clicking Arch switches between tray apps and workspaces", () => {
  const ready = stepReveal(initialReveal(), { type: "Ready" }).state;
  let state = stepReveal(ready, { type: "TrayHover", count: 1 }).state;
  const contents = () =>
    stripFor({
      activeId: 1,
      windows: [],
      monitor: "screen",
      minSlots: 1,
      special: "",
      flash: null,
      view: state.row,
      trayItems: [{ id: "steam", kind: "tray" }],
    }).items;

  assert.deepEqual(contents(), [{ id: "steam", kind: "tray" }]);
  state = stepReveal(state, { type: "ToggleTray" }).state;
  assert.deepEqual(contents(), [{ id: 1, kind: "active", cls: null }]);
  state = stepReveal(state, { type: "ToggleTray" }).state;
  assert.deepEqual(contents(), [{ id: "steam", kind: "tray" }]);
});
