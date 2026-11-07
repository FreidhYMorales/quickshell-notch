// Control center toggle tiles, in display order. A null state means the
// backend is missing, so its tile is not shown.

const ORDER = ["wifi", "bt", "dnd", "profile", "caffeine"];

/** tilesFor({ wifi, bt, dnd }) -> [{ id, on }] */
export function tilesFor(state) {
  const tiles = [];
  for (const id of ORDER) {
    const on = state[id];
    if (on === null || on === undefined) continue;
    tiles.push({ id, on: !!on });
  }
  return tiles;
}
