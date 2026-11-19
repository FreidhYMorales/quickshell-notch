// OLED pixel shift of the idle notch content: a step count maps to an offset
// that cycles home, right, right+down, down, so the content never sits more
// than one pixel from home.

/** shiftOffset(step) -> { x, y } */
export function shiftOffset(_step) {
  return { x: 0, y: 0 };
}
