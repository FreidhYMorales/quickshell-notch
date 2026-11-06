// Ordered queue for keybind and power-button requests that arrive before
// Hyprland has listed its monitors. Order and multiplicity are preserved: two
// fast presses must not collapse into one.

export function enqueue(queue, request) {
  return queue.concat([request]);
}

// A known monitor drains the whole queue; without one nothing is consumed.
export function take(queue, monitor) {
  if (!monitor) return { ready: [], rest: queue };
  return { ready: queue, rest: [] };
}
