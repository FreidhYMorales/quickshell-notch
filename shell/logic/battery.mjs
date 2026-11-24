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

// One layer for the idle notch: none, charging, plugged, full or low.
// "plugged" = on AC but not charging, e.g. held at a charge limit (80%).
export function classify(input, limits) {
  if (!input.present) return "none";
  if (input.plugged) {
    if (input.full) return "full";
    return input.charging ? "charging" : "plugged";
  }
  return input.percentage < limits.low ? "low" : "none";
}

// Stable colour bands for the idle notch, independent of plug state.
export function chargeStage(percentage, limits) {
  if (percentage < limits.low) return "low";
  if (percentage < limits.high) return "medium";
  return "high";
}

// Briefly reveal the side battery details when crossing a meaningful level.
// A configured charge cap takes precedence over the generic 60% crossing.
export function infoMilestone(previous, next, chargeLimit, limits) {
  if (!previous || !next.present || !previous.present) return null;
  if (
    chargeLimit > 0 && next.plugged && next.percentage >= chargeLimit &&
    (!previous.plugged || previous.percentage < chargeLimit)
  ) {
    return chargeLimit;
  }
  const crossed = (threshold) =>
    (previous.percentage < threshold && next.percentage >= threshold) ||
    (previous.percentage >= threshold && next.percentage < threshold);
  if (crossed(limits.high)) return limits.high;
  if (crossed(limits.low)) return limits.low;
  return null;
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

// sysfs reports energy in micro-Wh and everything else as plain text; an
// unreadable or negative value becomes 0 so the card can drop that figure.
function positive(text) {
  const value = parseFloat(text);
  return Number.isFinite(value) && value > 0 ? value : 0;
}

function microWh(text) {
  return Math.round(positive(text) / 1e5) / 10;
}

// Wear, capacity and the charge limit from /sys/class/power_supply/<battery>/
// (UPower has them on D-Bus, but Quickshell exposes neither health nor cycles).
// Health is what the pack holds today against what it held new: the `capacity`
// file is the current charge, not wear.
export function parseSysfs(
  { cycles, energyNow, energyFull, energyFullDesign, endThreshold },
) {
  const full = microWh(energyFull);
  const design = microWh(energyFullDesign);
  return {
    health: full > 0 && design > 0 ? Math.round((full / design) * 100) : 0,
    cycles: Math.round(positive(cycles)),
    energyNow: microWh(energyNow),
    energyFull: full,
    limit: Math.round(positive(endThreshold)),
  };
}
