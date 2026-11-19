// Fingerprint unlock on/off for the lock screen. Reads the notch state first,
// then the old shell's (read-only); a missing or unreadable file falls through.
function readFlag(text) {
  if (typeof text !== "string") return null;
  try {
    const value = JSON.parse(text).fingerprintEnabled;
    return typeof value === "boolean" ? value : null;
  } catch (_e) {
    return null;
  }
}

export function fingerprintEnabled(notchText, oldText) {
  const notch = readFlag(notchText);
  if (notch !== null) return notch;
  const old = readFlag(oldText);
  return old === null ? false : old;
}

export function serialiseSecurity(_enabled) {
  return "";
}
