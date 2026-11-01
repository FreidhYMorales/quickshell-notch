import { test } from "node:test";
import assert from "node:assert/strict";
import { stripFor } from "../shell/logic/workspaceStrip.mjs";

test("special workspace takes priority over the tray row", () => {
  const args = {
    special: "special:music",
    view: "tray",
    trayItems: [{ id: "steam", kind: "tray" }],
  };
  assert.deepEqual(stripFor(args), {
    pinned: true,
    special: "music",
    items: [],
  });
  assert.deepEqual(stripFor(Object.assign({}, args, { special: "" })), {
    pinned: false,
    special: "",
    items: [{ id: "steam", kind: "tray" }],
  });
});
