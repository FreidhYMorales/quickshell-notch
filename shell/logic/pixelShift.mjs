// OLED pixel shift of the idle notch content: a step count maps to an offset
// that cycles home, right, right+down, down, so the content never sits more
// than one pixel from home.

const CYCLE = [
  { x: 0, y: 0 },
  { x: 1, y: 0 },
  { x: 1, y: 1 },
  { x: 0, y: 1 },
];

/** shiftOffset(step) -> { x, y } */
export function shiftOffset(step) {
  const spot = CYCLE[step % CYCLE.length];
  return { x: spot.x, y: spot.y };
}
