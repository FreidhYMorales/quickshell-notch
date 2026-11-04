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
