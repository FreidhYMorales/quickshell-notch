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

// `date` = { year, month (1-12), day }; weekday 0 = Monday. `today` defaults
// to the centre; a browsed strip passes the real today so the mark stays put.
export function weekStrip(date, radius, today) {
  const centre = Date.UTC(date.year, date.month - 1, date.day);
  const todayKey = dayKey(today ?? date);
  const out = [];
  for (let offset = -radius; offset <= radius; offset++) {
    const d = new Date(centre + offset * DAY_MS);
    const cell = {
      year: d.getUTCFullYear(),
      month: d.getUTCMonth() + 1,
      day: d.getUTCDate(),
    };
    out.push({
      year: cell.year,
      month: cell.month,
      day: cell.day,
      weekday: (d.getUTCDay() + 6) % 7,
      today: dayKey(cell) === todayKey,
    });
  }
  return out;
}

// `date` moved by `days` (negative goes back).
export function shiftDays(date, days) {
  const d = new Date(
    Date.UTC(date.year, date.month - 1, date.day) + days * DAY_MS,
  );
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
  };
}

// `view` = { year, month } moved by `months` (negative goes back).
export function shiftMonth(view, months) {
  const index = view.year * 12 + (view.month - 1) + months;
  return { year: Math.floor(index / 12), month: (index % 12 + 12) % 12 + 1 };
}

const GRID_DAYS = 42;

// Six Monday-first weeks around `view` = { year, month }, so the grid keeps
// one height whatever the month; `today` = { year, month, day } is flagged.
export function monthGrid(view, today) {
  const first = Date.UTC(view.year, view.month - 1, 1);
  const lead = (new Date(first).getUTCDay() + 6) % 7;
  const start = first - lead * DAY_MS;
  const todayKey = dayKey(today);
  const out = [];
  for (let i = 0; i < GRID_DAYS; i++) {
    const d = new Date(start + i * DAY_MS);
    const cell = {
      year: d.getUTCFullYear(),
      month: d.getUTCMonth() + 1,
      day: d.getUTCDate(),
    };
    out.push({
      year: cell.year,
      month: cell.month,
      day: cell.day,
      inMonth: cell.month === view.month && cell.year === view.year,
      today: dayKey(cell) === todayKey,
    });
  }
  return out;
}
