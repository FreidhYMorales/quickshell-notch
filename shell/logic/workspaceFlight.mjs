// Decides how a window move is drawn on one monitor's workspace strip: the
// app icon flies between two shown slots, fades out at its slot when the
// window goes to a special workspace, or nothing happens.

function slotIndex(items, id) {
  for (let i = 0; i < items.length; i++) if (items[i].id === id) return i;
  return -1;
}

/** flightFor({ move, strip, row }) -> { kind, from, to?, cls } | null */
export function flightFor(args) {
  const move = args.move;
  // Only the workspace row of an unpinned strip shows slots; moves across
  // monitors are not animated.
  if (args.row === "tray" || args.strip.pinned || move.cross) return null;
  const items = args.strip.items;
  const from = slotIndex(items, move.from);
  if (from < 0) return null;
  // Special workspaces have negative ids in Hyprland.
  if (move.workspaceId < 0) return { kind: "fade", from, cls: move.cls };
  const to = slotIndex(items, move.workspaceId);
  if (to < 0) return null;
  return { kind: "fly", from, to, cls: move.cls };
}
