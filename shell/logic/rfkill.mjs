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
