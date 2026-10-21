// Pure rules for the cava visualizer: config text, frame parsing, bar
// geometry and accent choice. cava's stdout is untrusted input.

const MIN_SATURATION = 0.15; // below this a colour reads as grey

function clampInt(value, lo, hi) {
  const n = Math.floor(Number(value));
  if (!isFinite(n)) return lo;
  return Math.min(hi, Math.max(lo, n));
}

/** cavaConfig({ bars, framerate, maxRange }) -> config text (clamped integers only) */
export function cavaConfig({ bars, framerate, maxRange }) {
  return [
    "[general]",
    "bars = " + clampInt(bars, 1, 64),
    "framerate = " + clampInt(framerate, 1, 60),
    "autosens = 1",
    "[output]",
    "method = raw",
    "raw_target = /dev/stdout",
    "data_format = ascii",
    "ascii_max_range = " + clampInt(maxRange, 1, 1000),
    "bar_delimiter = 59",
    "frame_delimiter = 10",
    "channels = mono",
    "",
  ].join("\n");
}

/** parseFrame("3;5;0;", bars, maxRange) -> number[] (0..1) | null */
export function parseFrame(line, bars, maxRange) {
  if (typeof line !== "string") return null;
  const tokens = line.split(";");
  if (tokens.length > 0 && tokens[tokens.length - 1] === "") tokens.pop();
  if (tokens.length !== bars) return null;
  const levels = [];
  for (let i = 0; i < tokens.length; i++) {
    if (!/^\d+$/.test(tokens[i])) return null;
    levels.push(Math.min(1, Number(tokens[i]) / maxRange));
  }
  return levels;
}

/** barGeometry(levels, { height, barWidth, gap, minHeight }) -> [{ x, y, height }] */
export function barGeometry(levels, { height, barWidth, gap, minHeight }) {
  const bars = [];
  for (let i = 0; i < levels.length; i++) {
    const h = Math.max(minHeight, levels[i] * height);
    bars.push({ x: i * (barWidth + gap), y: (height - h) / 2, height: h });
  }
  return bars;
}

/** pickAccent([{ r, g, b }], { minLuma }) -> index of the most saturated bright colour | -1 */
export function pickAccent(colours, { minLuma }) {
  if (!colours) return -1;
  let best = -1;
  let bestSat = -1;
  for (let i = 0; i < colours.length; i++) {
    const col = colours[i];
    if (!col || !isFinite(col.r) || !isFinite(col.g) || !isFinite(col.b)) {
      continue;
    }
    const max = Math.max(col.r, col.g, col.b);
    const min = Math.min(col.r, col.g, col.b);
    const luma = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
    if (max <= 0 || luma < minLuma) continue;
    const sat = (max - min) / max;
    if (sat >= MIN_SATURATION && sat > bestSat) {
      best = i;
      bestSat = sat;
    }
  }
  return best;
}
