// Fingerprint management for the security view: reads fprintd's output.

// fprintd-list prints one " - #N: <finger>" line per registered finger.
export function enrolledFingers(text) {
  const names = [];
  const pattern = /-\s*#\d+:\s*(\S+)/g;
  let match = pattern.exec(text);
  while (match !== null) {
    names.push(match[1]);
    match = pattern.exec(text);
  }
  return names;
}

// fprintd-enroll statuses that end the enrollment without success.
const failures = [
  "enroll-failed",
  "enroll-disconnected",
  "enroll-unknown-error",
  "enroll-data-full",
  "enroll-duplicate",
];

// One "Enroll result: <status>" line: a counted touch, a hint key for the
// view (the status without its "enroll-" prefix) or the end of the enrollment.
export function enrollResult(line) {
  const match = /Enroll result:\s*(\S+)/.exec(line);
  if (match === null) return null;
  const status = match[1];
  if (status === "enroll-stage-passed") {
    return { touch: true, hint: "again", end: "" };
  }
  if (status === "enroll-completed") {
    return { touch: false, hint: "", end: "completed" };
  }
  if (failures.indexOf(status) !== -1) {
    return { touch: false, hint: "", end: "failed" };
  }
  return { touch: false, hint: status.replace(/^enroll-/, ""), end: "" };
}

// The ten finger names fprintd-enroll accepts, in the order the view lists them.
const fingers = [
  "left-thumb",
  "left-index-finger",
  "left-middle-finger",
  "left-ring-finger",
  "left-little-finger",
  "right-thumb",
  "right-index-finger",
  "right-middle-finger",
  "right-ring-finger",
  "right-little-finger",
];

const handPositions = [
  { name: "left-little-finger", x: 0.06, y: 18, rotation: -10 },
  { name: "left-ring-finger", x: 0.15, y: 2, rotation: -5 },
  { name: "left-middle-finger", x: 0.24, y: 0, rotation: 0 },
  { name: "left-index-finger", x: 0.33, y: 8, rotation: 5 },
  { name: "left-thumb", x: 0.42, y: 38, rotation: 32 },
  { name: "right-thumb", x: 0.58, y: 38, rotation: -32 },
  { name: "right-index-finger", x: 0.67, y: 8, rotation: -5 },
  { name: "right-middle-finger", x: 0.76, y: 0, rotation: 0 },
  { name: "right-ring-finger", x: 0.85, y: 2, rotation: 5 },
  { name: "right-little-finger", x: 0.94, y: 18, rotation: 10 },
];

export function fingerLayout() {
  return handPositions.map((entry) => Object.assign({}, entry));
}

export function fingerMatchFromSignal(line) {
  const match = /VerifyFingerMatched\s+\(['"]([^'"]+)['"]/.exec(line);
  if (match === null || fingers.indexOf(match[1]) === -1) return null;
  return match[1];
}

export function freeFingers(enrolled) {
  return fingers.filter((name) => enrolled.indexOf(name) === -1);
}
