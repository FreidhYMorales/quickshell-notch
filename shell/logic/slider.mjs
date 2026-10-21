// Slider maths shared by the volume and brightness OSDs. Range-generic:
// geo = { track, min, max } where track is the usable pixel travel
// (width minus thumb). Results are rounded to 3 decimals so repeated wheel
// steps never show float noise such as 0.55000000001.

const round3 = (n) => Math.round(n * 1000) / 1000;

export function clamp(v, min, max) {
  return Math.max(min, Math.min(v, max));
}

/** Pixel position along the track -> value in the range. */
export function valueAt(pos, geo) {
  if (!(geo.track > 0)) return geo.min;
  const t = clamp(pos, 0, geo.track) / geo.track;
  return round3(geo.min + t * (geo.max - geo.min));
}

/** Value -> pixel position; values outside the range pin to the ends. */
export function positionOf(value, geo) {
  const span = geo.max - geo.min;
  if (!(geo.track > 0) || !(span > 0)) return 0;
  return ((clamp(value, geo.min, geo.max) - geo.min) / span) * geo.track;
}

/** Wheel angleDelta.y -> whole notches (one per 120); partial deltas are 0. */
export function notchesOf(angleDeltaY) {
  return Math.trunc(angleDeltaY / 120) + 0; // + 0 turns -0 into 0
}

/** Apply `notches` steps (up = +) and clamp to the range. */
export function wheel(value, notches, opts) {
  return round3(clamp(value + notches * opts.step, opts.min, opts.max));
}

/**
 * Icon for a level. fraction is 0..1 of the range; levels: { high, mid }
 * thresholds; glyphs: { muted, low, mid, high }.
 */
export function levelGlyph(fraction, muted, levels, glyphs) {
  if (muted) return glyphs.muted;
  if (fraction >= levels.high) return glyphs.high;
  if (fraction >= levels.mid) return glyphs.mid;
  return glyphs.low;
}

/**
 * Number shown beside the slider. Not clamped from above: a volume above 100%
 * reports its real percent while the bar stays full. Never negative.
 */
export function displayPercent(value, geo) {
  const span = geo.max - geo.min;
  if (!(span > 0)) return 0;
  return Math.max(0, Math.round(((value - geo.min) / span) * 100));
}
