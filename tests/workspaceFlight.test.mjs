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

// Spec: nothing flies when an end is missing or the strip shows something else.
for (
  const [name, args] of [
    ["destination beyond the shown slots", {
      move: move(1, 9),
      strip,
      row: "workspaces",
    }],
    ["source beyond the shown slots", {
      move: move(9, 1),
      strip,
      row: "workspaces",
    }],
    ["special from a slot not shown", {
      move: move(9, -98),
      strip,
      row: "workspaces",
    }],
    ["the tray row is shown", { move: move(1, 3), strip, row: "tray" }],
    ["the strip is pinned to a special", {
      move: move(1, 3),
      strip: { pinned: true, special: "magic", items: [] },
      row: "workspaces",
    }],
    ["the move crosses monitors", {
      move: move(1, 3, { cross: true }),
      strip,
      row: "workspaces",
    }],
  ]
) {
  test(`flightFor: nothing when ${name}`, () => {
    assert.equal(flightFor(args), null);
  });
}
