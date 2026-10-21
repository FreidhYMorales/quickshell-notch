// Size of the TL corner body. The ears flare along the top and left screen
// edges, so the body is its content plus padding on both sides and one ear
// radius of extra width (top flare) and height (left flare). Capped to the
// slot so the shape never leaves its fixed-size surface.

const atLeast0 = (n) => Math.max(0, n);

/** { contentWidth, contentHeight, pad, ear, maxWidth, maxHeight } -> { width, height } */
export function cornerShape(p) {
  const ear = atLeast0(p.ear);
  const width = atLeast0(p.contentWidth) + 2 * atLeast0(p.pad) + ear;
  const height = atLeast0(p.contentHeight) + ear;
  return {
    width: Math.min(width, atLeast0(p.maxWidth)),
    height: Math.min(height, atLeast0(p.maxHeight)),
  };
}
