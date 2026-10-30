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

// The drawn body inside a top corner shape: one ear less in width (on the
// side away from the screen corner) and in height.
/** ({ width, height }, ear, "topLeft" | "topRight") -> { x, y, width, height } */
export function cornerBody(size, ear, anchor) {
  const e = atLeast0(ear);
  return {
    x: anchor === "topRight" ? e : 0,
    y: 0,
    width: atLeast0(size.width - e),
    height: atLeast0(size.height - e),
  };
}

// Vertical offset of a shape sliding down from the top edge. Animate
// `progress` (0 hidden, 1 shown), not y: then a height change while hidden
// stays hidden instead of animating into view.
export function slideOffset(height, progress) {
  return (progress - 1) * height;
}
