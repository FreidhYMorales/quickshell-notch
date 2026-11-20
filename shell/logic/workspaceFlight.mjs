// Decides how a window move is drawn on one monitor's workspace strip: the
// app icon flies between two shown slots, fades out at its slot when the
// window goes to a special workspace, or nothing happens.

function slotIndex(items, id) {
  for (let i = 0; i < items.length; i++) if (items[i].id === id) return i;
  return -1;
}

/** flightFor({ move, strip, row }) -> { kind, from, to?, cls } | null */
export function flightFor(args) {
  const items = args.strip.items;
  const from = slotIndex(items, args.move.from);
  // Special workspaces have negative ids in Hyprland.
  if (args.move.workspaceId < 0) {
    return { kind: "fade", from, cls: args.move.cls };
  }
  const to = slotIndex(items, args.move.workspaceId);
  return { kind: "fly", from, to, cls: args.move.cls };
}
