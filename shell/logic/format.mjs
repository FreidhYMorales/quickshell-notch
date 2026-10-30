// Pure display text. Month names come from the caller (Strings), so nothing
// here depends on the system locale.

function pad2(n) {
  return n < 10 ? "0" + n : String(n);
}

// 24-hour clock, e.g. "14:32".
export function clock(hours, minutes) {
  return pad2(hours) + ":" + pad2(minutes);
}

// `month` is 1-12; `months` is a 0-based list of short names.
export function shortDate(month, day, months) {
  return months[month - 1] + " " + day;
}

// Whole-number percent, e.g. 71.6 -> "72%".
export function formatPercent(value) {
  return Math.round(value) + "%";
}

// Whole seconds from /proc/uptime ("11520.37 45678.90"); null if unreadable.
export function parseUptime(text) {
  const seconds = Math.floor(parseFloat(text));
  return seconds >= 0 ? seconds : null;
}
