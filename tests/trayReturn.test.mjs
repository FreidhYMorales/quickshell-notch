import { test } from "node:test";
import assert from "node:assert/strict";
import { initialReveal, stepReveal } from "../shell/logic/reveal.mjs";
import { stripFor } from "../shell/logic/workspaceStrip.mjs";

test("workspace activity shows workspaces again after the tray closes", () => {
  const ready = stepReveal(initialReveal(), { type: "Ready" }).state;
  const tray = stepReveal(ready, { type: "TrayHover", count: 1 }).state;
  const contents = (state) =>
    stripFor({
      activeId: 1,
      windows: [],
      monitor: "screen",
      minSlots: 1,
      special: "",
      view: state.row,
      trayItems: [{ id: "steam", kind: "tray" }],
    }).items;
  const stillOpen = stepReveal(tray, { type: "Trigger" }).state;
  assert.deepEqual(contents(stillOpen), [{ id: "steam", kind: "tray" }]);
  const left = stepReveal(stillOpen, { type: "Hover", on: false }).state;
  const closed = stepReveal(left, { type: "Timeout" }).state;
  const reopened = stepReveal(closed, { type: "Trigger" }).state;
  assert.deepEqual(contents(reopened), [{ id: 1, kind: "active", cls: null }]);
});
