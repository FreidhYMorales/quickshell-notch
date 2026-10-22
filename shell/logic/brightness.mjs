// Backlight rules. brightnessctl output is untrusted text: every parser
// returns null on anything unexpected, and the set argv is built from a
// clamped integer only, so no caller string ever reaches a process.

/** `brightnessctl get` / `max` output -> non-negative integer | null. */
export function parseLevel(line) {
  if (typeof line !== "string") return null;
  const text = line.trim();
  if (!/^\d+$/.test(text)) return null;
  const n = Number(text);
  return Number.isSafeInteger(n) ? n : null;
}

const usable = (n) => typeof n === "number" && Number.isFinite(n);

/** current / max -> integer percent 0..100 | null when unusable. */
export function percentOf(current, max) {
  if (!usable(current) || !usable(max) || max <= 0 || current < 0) return null;
  return Math.min(100, Math.round((current / max) * 100));
}

/** Percent -> brightnessctl argv with a clamped integer, null if not a number. */
export function setArgs(percent) {
  if (!usable(percent)) return null;
  const p = Math.max(0, Math.min(100, Math.round(percent)));
  return ["brightnessctl", "set", `${p}%`];
}
