// Control center toggle tiles, in display order. A null state means the
// backend is missing, so its tile is not shown. The profile is a three-state
// value, so its tile reads as "on" whenever it is not the neutral one.

const ORDER = ["wifi", "bt", "dnd", "profile", "caffeine"];
const NEUTRAL_PROFILE = "balanced";

/** tilesFor({ wifi, bt, dnd, profile, caffeine }) -> [{ id, on }] */
export function tilesFor(state) {
  const tiles = [];
  for (const id of ORDER) {
    const value = state[id];
    if (value === null || value === undefined) continue;
    tiles.push({
      id,
      on: id === "profile" ? value !== NEUTRAL_PROFILE : !!value,
    });
  }
  return tiles;
}
