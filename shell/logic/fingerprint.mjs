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

export function enrollResult(_line) {
  return null;
}
