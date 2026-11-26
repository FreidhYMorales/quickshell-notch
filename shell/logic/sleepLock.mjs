// Lock before sleep: decisions driven by logind's PrepareForSleep signal.

const SIGNAL = "org.freedesktop.login1.Manager.PrepareForSleep (";

export function parsePreparingForSleep(reply) {
  if (reply.includes("<true>")) return true;
  if (reply.includes("<false>")) return false;
  return null;
}

export function monitorRetryDelay(attempt) {
  return Math.min(250 * 2 ** Math.max(0, attempt - 1), 5000);
}

// A `gdbus monitor` line -> true (going to sleep), false (resumed) or null.
export function parseSleepSignal(line) {
  const at = line.indexOf(SIGNAL);
  if (at < 0) return null;
  const arg = line.slice(at + SIGNAL.length);
  if (arg.startsWith("true")) return true;
  if (arg.startsWith("false")) return false;
  return null;
}

// state { sleeping, locked } + event { type: "PrepareForSleep" | "Locked", on }
// -> next state plus what to do: requestLock (ask for the lock now) and
// inhibit (hold logind's delay inhibitor). The inhibitor is held while awake
// and released only once the session is locked on the way to sleep.
export function sleepStep(state, event) {
  const sleeping = event.type === "PrepareForSleep" ? event.on : state.sleeping;
  const locked = event.type === "Locked" ? event.on : state.locked;
  const goingToSleep = event.type === "PrepareForSleep" && event.on;
  return {
    sleeping: sleeping,
    locked: locked,
    requestLock: goingToSleep && !locked,
    inhibit: !(sleeping && locked),
  };
}
