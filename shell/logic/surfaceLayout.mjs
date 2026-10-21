// Pure slot placement for one monitor. All five slots share the top row,
// left to right: tl, bl (brightness OSD), c, vr (volume OSD), tr. None overlap.
// The centre is sized first; each OSD takes what is left beside it.

/**
 * tokens: { idleHeight, cornerWidth, osdWidth, gap, centerMaxWidth,
 *           centerMaxWidthByMonitor?, expandedHeight?, cornerHeight?,
 *           osdHeight? }
 * cornerHeight sizes TL, osdHeight sizes BL and VR; both default to idleHeight.
 */
export function layoutFor(screenWidth, monitorName, tokens) {
  const { gap } = tokens;
  const height = tokens.idleHeight;
  const corner = Math.min(tokens.cornerWidth, screenWidth / 2);
  const requested = tokens.centerMaxWidthByMonitor?.[monitorName] ??
    tokens.centerMaxWidth;
  const available = Math.max(0, screenWidth - 2 * (corner + gap));
  const width = Math.min(requested, available);
  const cx = (screenWidth - width) / 2;
  const osd = Math.min(tokens.osdWidth, Math.max(0, cx - corner - 2 * gap));
  // Centre each OSD in the free space between its corner and the centre.
  const osdHeight = tokens.osdHeight ?? height;
  const blx = (corner + cx) / 2 - osd / 2;
  return {
    tl: { x: 0, width: corner, height: tokens.cornerHeight ?? height },
    bl: { x: blx, width: osd, height: osdHeight },
    c: { x: cx, width, height: tokens.expandedHeight ?? height },
    vr: { x: screenWidth - blx - osd, width: osd, height: osdHeight },
    tr: { x: screenWidth - corner, width: corner, height },
  };
}
