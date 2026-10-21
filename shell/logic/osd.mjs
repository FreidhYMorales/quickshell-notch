// OSD reveal rule. A sample is { available, source, value, muted } where
// source identifies the device (default sink id, backlight name).

const EPSILON = 1e-6;

/**
 * True when the user-visible level changed on the same, available device.
 * The initial read (unavailable -> available), device switches and a missing
 * sample never count, so only real changes reveal.
 */
export function shouldReveal(prev, next) {
  if (!prev || !next) return false;
  if (!prev.available || !next.available) return false;
  if (prev.source !== next.source) return false;
  return Math.abs(next.value - prev.value) > EPSILON ||
    !!next.muted !== !!prev.muted;
}
