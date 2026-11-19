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
