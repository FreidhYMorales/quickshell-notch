// Pure slot placement for one monitor. The top row (tl, c, tr) never overlaps.
// bl and vr sit on the left and right screen edges, off the top row.

/**
 * tokens: { idleHeight, cornerWidth, osdWidth, gap, centerMaxWidth,
 *           centerMaxWidthByMonitor? }
 */
export function layoutFor(screenWidth, monitorName, tokens) {
  const height = tokens.idleHeight;
  const corner = Math.min(tokens.cornerWidth, screenWidth / 2);
  const requested = tokens.centerMaxWidthByMonitor?.[monitorName] ??
    tokens.centerMaxWidth;
  const available = Math.max(0, screenWidth - 2 * (corner + tokens.gap));
  const width = Math.min(requested, available);
  return {
    tl: { x: 0, width: corner, height },
    bl: { x: 0, width: corner, height },
    c: { x: (screenWidth - width) / 2, width, height },
    vr: { x: screenWidth - tokens.osdWidth, width: tokens.osdWidth, height },
    tr: { x: screenWidth - corner, width: corner, height },
  };
}
