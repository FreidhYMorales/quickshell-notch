// Idle chain decisions: timeouts are in minutes, delays in seconds.

// The lock fires after screensaver + lock minutes; suspend after all three.
// A step whose own minutes are zero is off (null).
export function idleDelays(timeouts) {
  const lockMin = timeouts.screensaver + timeouts.lock;
  return {
    lockSec: lockMin > 0 ? lockMin * 60 : null,
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
export function parseIdle(text) {
  let saved = {};
  if (typeof text === "string") {
    try {
      saved = JSON.parse(text) || {};
    } catch (_e) {
      saved = {};
    }
  }
  const timeouts = {};
  for (const key in FIELDS) {
    const value = saved[FIELDS[key]];
    timeouts[key] = typeof value === "number" ? value : DEFAULTS[key];
  }
  return timeouts;
}
