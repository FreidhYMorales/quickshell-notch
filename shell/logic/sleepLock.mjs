// Lock before sleep: decisions driven by logind's PrepareForSleep signal.

const SIGNAL = "org.freedesktop.login1.Manager.PrepareForSleep (";

// A `gdbus monitor` line -> true (going to sleep), false (resumed) or null.
export function parseSleepSignal(line) {
  const at = line.indexOf(SIGNAL);
  if (at < 0) return null;
  const arg = line.slice(at + SIGNAL.length);
  if (arg.startsWith("true")) return true;
  if (arg.startsWith("false")) return false;
  return null;
}
