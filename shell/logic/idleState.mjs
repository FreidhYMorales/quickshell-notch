// Idle chain stages: timeouts are in minutes, delays in seconds.

// The screensaver starts at its own minutes, the screen goes black after
// screensaver + lock minutes and suspend after all three. A stage whose own
// minutes are zero is off (null); the later stages still count from the sum.
export function idleDelays(timeouts) {
  const lockMin = timeouts.screensaver + timeouts.lock;
  return {
    screensaverSec: timeouts.screensaver > 0 ? timeouts.screensaver * 60 : null,
    lockSec: timeouts.lock > 0 ? lockMin * 60 : null,
    suspendSec: timeouts.suspend > 0 ? (lockMin + timeouts.suspend) * 60 : null,
  };
}

const DEFAULTS = { screensaver: 3, lock: 5, suspend: 15 };
const FIELDS = {
  screensaver: "screensaverTimeoutMin",
  lock: "lockTimeoutMin",
  suspend: "suspendTimeoutMin",
};

// Timeouts from an idle.json text (the old shell's format); a missing or
// non-numeric field takes its default, an unreadable file all of them.
function readSaved(text) {
  if (typeof text !== "string") return {};
  try {
    return JSON.parse(text) || {};
  } catch (_e) {
    return {};
  }
}

export function parseIdle(text) {
  const saved = readSaved(text);
  const timeouts = {};
  for (const key in FIELDS) {
    const value = saved[FIELDS[key]];
    timeouts[key] = typeof value === "number" ? value : DEFAULTS[key];
  }
  return timeouts;
}

const MAX_MINUTES = 60;

// One stepper press: 0 is Off and 60 the most the view offers.
export function stepMinutes(value, step) {
  return Math.min(MAX_MINUTES, Math.max(0, value + step));
}

// The idle.json object: the old shell's field names, including its wallpaper
// choice, so either shell reads the other's file.
export function serialiseIdle(timeouts, choice) {
  const saved = {};
  for (const key in FIELDS) saved[FIELDS[key]] = timeouts[key];
  saved.screensaverUseWallpaper = choice.sameAsDesktop;
  saved.screensaverPath = choice.path;
  return saved;
}

// The screensaver wallpaper choice from an idle.json text: the desktop
// wallpaper unless the file turns it off, and the chosen path when it has one.
export function parseScreensaverChoice(text) {
  const saved = readSaved(text);
  return {
    sameAsDesktop: saved.screensaverUseWallpaper !== false,
    path: typeof saved.screensaverPath === "string"
      ? saved.screensaverPath
      : "",
  };
}

// The image a monitor shows during the screensaver: the chosen wallpaper when
// the "same as desktop" switch is off and one is chosen, else its own.
export function screensaverImage(monitorPath, choice) {
  return !choice.sameAsDesktop && choice.path !== ""
    ? choice.path
    : monitorPath;
}
