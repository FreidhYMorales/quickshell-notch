import { test } from "node:test";
import assert from "node:assert/strict";
import { flightFor } from "../shell/logic/workspaceFlight.mjs";

// A five-slot strip on workspaces 1-5, active 1.
const strip = {
  pinned: false,
  special: "",
  items: [
    { id: 1, kind: "active", cls: null },
    { id: 2, kind: "empty", cls: null },
    { id: 3, kind: "app", cls: "kitty" },
    { id: 4, kind: "empty", cls: null },
    { id: 5, kind: "empty", cls: null },
  ],
};
const move = (from, to, extra) =>
  Object.assign({ kind: "move", workspaceId: to, cls: "kitty", from }, extra);

test("flightFor: a move between two shown slots flies between them", () => {
  assert.deepEqual(flightFor({ move: move(1, 3), strip, row: "workspaces" }), {
    kind: "fly",
    from: 0,
    to: 2,
    cls: "kitty",
  });
});

test("flightFor: a move to a special fades out at the source slot", () => {
  assert.deepEqual(
    flightFor({ move: move(3, -98), strip, row: "workspaces" }),
    { kind: "fade", from: 2, cls: "kitty" },
  );
});
