// Pure parsing of `rfkill event` lines, e.g.
// "2026-10-30 13:02:47,762279-06:00: idx 2 type 1 op 0 soft 0 hard 0".
// Type and op codes are the kernel's RFKILL_TYPE_* and RFKILL_OP_*.

const TYPES = [
  "all",
  "wlan",
  "bluetooth",
  "uwb",
  "wimax",
  "wwan",
  "gps",
  "fm",
  "nfc",
];
const OPS = ["add", "del", "change", "changeAll"];
const EVENT = /idx (\d+) type (\d+) op (\d+) soft (\d+) hard (\d+)\s*$/;

/** parseRfkillEvent(line) -> { idx, type, op, soft, hard } | null */
export function parseRfkillEvent(line) {
  const m = EVENT.exec(line ?? "");
  if (!m) return null;
  const type = TYPES[Number(m[2])];
  const op = OPS[Number(m[3])];
  if (type === undefined || op === undefined) return null;
  return {
    idx: Number(m[1]),
    type,
    op,
    soft: m[4] !== "0",
    hard: m[5] !== "0",
  };
}

// devices: { [idx]: { type, soft, hard } }. Returns a new object; add and
// change record the device, del forgets it, anything else changes nothing.
export function applyRfkillEvent(devices, event) {
  const next = Object.assign({}, devices);
  if (event.op === "add" || event.op === "change") {
    next[event.idx] = { type: event.type, soft: event.soft, hard: event.hard };
  } else if (event.op === "del") {
    delete next[event.idx];
  }
  return next;
}

// true if any wlan radio is unblocked, false if all are blocked, null if
// there is no wlan radio at all (the tile hides).
export function wifiOn(devices) {
  let found = false;
  for (const idx in devices) {
    const d = devices[idx];
    if (d.type !== "wlan") continue;
    if (!d.soft && !d.hard) return true;
    found = true;
  }
  return found ? false : null;
}
