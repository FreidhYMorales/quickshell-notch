// Pure widths for the centre notch shape. Any battery layer that shows
// (charging, plugged, full, low) grows the idle notch by `side` on both
// sides, so the clock keeps its position.

export function idleWidth({ base, side, layer, max }) {
  const extra = layer !== "none" ? 2 * side : 0;
  return Math.min(base + extra, max);
}

export function expandedWidth({ hasPlayer, full, clockOnly, max }) {
  return Math.min(hasPlayer ? full : clockOnly, max);
}

// widths / heights: { idle, expanded }.
export function shapeFor(mode, widths, heights) {
  const key = mode === "expanded" ? "expanded" : "idle";
  return { width: widths[key], height: heights[key] };
}
