// Power profiles: the names the daemon reports and the order a tile click
// walks through them.

export const PROFILES = ["performance", "balanced", "power-saver"];

/** cycleProfile(current) -> the next profile, wrapping around. */
export function cycleProfile(current) {
  const index = PROFILES.indexOf(current);
  return PROFILES[(index + 1) % PROFILES.length];
}
