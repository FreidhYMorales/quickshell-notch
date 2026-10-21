// Pure battery rules. The service maps UPower enums to strings before calling
// in, so nothing here depends on Quickshell or Qt.

const PLUGGED_STATES = ["charging", "full", "pending-charge"];

function toPercent(fraction) {
  const value = Number(fraction);
  if (!Number.isFinite(value)) return 0;
  return Math.round(Math.min(1, Math.max(0, value)) * 100);
}

// UPower reports the charge as a 0-1 fraction; `onBattery` is the daemon's
// line-power aggregate (true when unplugged).
export function fromUPower({ present, onBattery, state, fraction }) {
  return {
    present: !!present,
    plugged: !onBattery || PLUGGED_STATES.indexOf(state) !== -1,
    charging: state === "charging",
    full: state === "full",
    percentage: toPercent(fraction),
  };
}

// One layer for the idle notch: none, charging, full or low.
export function classify(input, limits) {
  if (!input.present) return "none";
  if (input.plugged) {
    if (input.full) return "full";
    return input.charging ? "charging" : "none";
  }
  return input.percentage < limits.low ? "low" : "none";
}

// Dev override: forced fields replace the real ones; null keeps the input.
export function applyOverride(input, override) {
  return override ? Object.assign({}, input, override) : input;
}

// One-shot critical event: fires once when unplugged at or below the critical
// limit, and re-arms only when power is connected.
export function criticalStep(state, input, limits) {
  if (!input.present) return { fire: false, armed: state.armed };
  if (input.plugged) return { fire: false, armed: true };
  if (state.armed && input.percentage <= limits.critical) {
    return { fire: true, armed: false };
  }
  return { fire: false, armed: state.armed };
}

export function edges(prev, next) {
  return {
    pluggedIn: !prev.plugged && next.plugged,
    unplugged: prev.plugged && !next.plugged,
    fullReached: !prev.full && next.full,
  };
}
