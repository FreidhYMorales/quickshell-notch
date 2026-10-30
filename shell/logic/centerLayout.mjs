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

// Idle notch width with no side layer: the row, symmetric padding and the
// flare of both ears.
export function idleBase({ row, pad, ear }) {
  return row + 2 * pad + 2 * ear;
}

// What one side layer adds on EACH side: the wider of the two items plus the
// gap that keeps it adjacent to the row. A zero width means "absent".
export function sideExtent({ left, right, gap }) {
  return Math.max(left, right) + gap;
}

// Toast shape: compact, or larger with body and actions while hovered.
// widths / heights: { compact, expanded }.
export function toastShape({ expanded, widths, heights, max }) {
  const key = expanded ? "expanded" : "compact";
  return { width: Math.min(widths[key], max), height: heights[key] };
}
