// Idle chain decisions: timeouts are in minutes, delays in seconds.

// The lock fires after screensaver + lock minutes; suspend after all three.
export function idleDelays(timeouts) {
  const lockMin = timeouts.screensaver + timeouts.lock;
  return {
    lockSec: lockMin * 60,
    suspendSec: (lockMin + timeouts.suspend) * 60,
  };
}
