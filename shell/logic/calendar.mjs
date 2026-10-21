// Pure calendar rules on plain y/m/d fields. Date.UTC math keeps results
// independent of locale, timezone and DST.

const DAY_MS = 86400000;

function pad(n, width) {
  let s = String(n);
  while (s.length < width) s = "0" + s;
  return s;
}

export function dayKey(d) {
  return pad(d.year, 4) + "-" + pad(d.month, 2) + "-" + pad(d.day, 2);
}

// `date` = { year, month (1-12), day }; weekday 0 = Monday.
export function weekStrip(date, radius) {
  const centre = Date.UTC(date.year, date.month - 1, date.day);
  const out = [];
  for (let offset = -radius; offset <= radius; offset++) {
    const d = new Date(centre + offset * DAY_MS);
    out.push({
      year: d.getUTCFullYear(),
      month: d.getUTCMonth() + 1,
      day: d.getUTCDate(),
      weekday: (d.getUTCDay() + 6) % 7,
      today: offset === 0,
    });
  }
  return out;
}
