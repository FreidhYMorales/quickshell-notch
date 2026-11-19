import { test } from "node:test";
import assert from "node:assert/strict";
import {
  dayKey,
  monthGrid,
  shiftDays,
  shiftMonth,
  weekStrip,
} from "../shell/logic/calendar.mjs";

const days = (strip) => strip.map((d) => d.day);

// Spec table: [today, expected day numbers, expected "M/D" of first and last].
const TABLE = [
  [
    { year: 2026, month: 3, day: 20 },
    [17, 18, 19, 20, 21, 22, 23],
    "2026-03-17",
    "2026-03-23",
  ],
  [
    { year: 2026, month: 3, day: 31 },
    [28, 29, 30, 31, 1, 2, 3],
    "2026-03-28",
    "2026-04-03",
  ],
  [
    { year: 2026, month: 12, day: 31 },
    [28, 29, 30, 31, 1, 2, 3],
    "2026-12-28",
    "2027-01-03",
  ],
  [
    { year: 2026, month: 1, day: 2 },
    [30, 31, 1, 2, 3, 4, 5],
    "2025-12-30",
    "2026-01-05",
  ],
  [
    { year: 2024, month: 2, day: 28 },
    [25, 26, 27, 28, 29, 1, 2],
    "2024-02-25",
    "2024-03-02",
  ],
];

for (const [today, expected, first, last] of TABLE) {
  test(`weekStrip around ${dayKey(today)}`, () => {
    const strip = weekStrip(today, 3);
    assert.deepEqual(days(strip), expected);
    assert.equal(dayKey(strip[0]), first);
    assert.equal(dayKey(strip[6]), last);
  });
}

test("weekStrip flags only the centre as today", () => {
  const strip = weekStrip({ year: 2026, month: 3, day: 20 }, 3);
  assert.deepEqual(strip.map((d) => d.today), [
    false,
    false,
    false,
    true,
    false,
    false,
    false,
  ]);
});

test("weekStrip weekday is 0=Monday", () => {
  // 2026-03-20 is a Friday.
  const strip = weekStrip({ year: 2026, month: 3, day: 20 }, 3);
  assert.deepEqual(strip.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 0]);
});

test("weekStrip honours the radius", () => {
  const strip = weekStrip({ year: 2026, month: 3, day: 20 }, 1);
  assert.deepEqual(days(strip), [19, 20, 21]);
});

test("dayKey pads and changes at midnight", () => {
  assert.equal(dayKey({ year: 2026, month: 3, day: 5 }), "2026-03-05");
  assert.notEqual(
    dayKey({ year: 2026, month: 3, day: 20 }),
    dayKey({ year: 2026, month: 3, day: 21 }),
  );
});

test("midnight rollover recentres the strip on the next day", () => {
  const next = weekStrip({ year: 2026, month: 3, day: 21 }, 3);
  assert.deepEqual(days(next), [18, 19, 20, 21, 22, 23, 24]);
  assert.equal(next[3].today, true);
});

test("the month grid starts on Monday, fills from the neighbouring months and marks today", () => {
  const grid = monthGrid({ year: 2026, month: 11 }, {
    year: 2026,
    month: 11,
    day: 19,
  });
  assert.equal(grid.length, 42);
  // November 2026 starts on a Sunday: Mon 26 Oct opens the grid.
  assert.deepEqual(grid[0], {
    year: 2026,
    month: 10,
    day: 26,
    inMonth: false,
    today: false,
  });
  assert.deepEqual(grid[6], {
    year: 2026,
    month: 11,
    day: 1,
    inMonth: true,
    today: false,
  });
  assert.deepEqual(grid[24], {
    year: 2026,
    month: 11,
    day: 19,
    inMonth: true,
    today: true,
  });
  assert.deepEqual(grid[41], {
    year: 2026,
    month: 12,
    day: 6,
    inMonth: false,
    today: false,
  });
  assert.equal(grid.filter((d) => d.today).length, 1);
  assert.equal(grid.filter((d) => d.inMonth).length, 30);
});

test("a month starting on Monday opens the grid with its first day and has no today elsewhere", () => {
  const grid = monthGrid({ year: 2027, month: 2 }, {
    year: 2026,
    month: 11,
    day: 19,
  });
  assert.equal(grid.length, 42);
  assert.deepEqual(grid[0], {
    year: 2027,
    month: 2,
    day: 1,
    inMonth: true,
    today: false,
  });
  assert.deepEqual(grid[28], {
    year: 2027,
    month: 3,
    day: 1,
    inMonth: false,
    today: false,
  });
  assert.equal(grid.filter((d) => d.today).length, 0);
  assert.equal(grid.filter((d) => d.inMonth).length, 28);
});

test("a week step moves the date by seven days across the year", () => {
  assert.deepEqual(shiftDays({ year: 2026, month: 12, day: 29 }, 7), {
    year: 2027,
    month: 1,
    day: 5,
  });
  assert.deepEqual(shiftDays({ year: 2026, month: 11, day: 19 }, -14), {
    year: 2026,
    month: 11,
    day: 5,
  });
});

test("a month step moves by whole months across years", () => {
  assert.deepEqual(shiftMonth({ year: 2026, month: 12 }, 1), {
    year: 2027,
    month: 1,
  });
  assert.deepEqual(shiftMonth({ year: 2026, month: 1 }, -1), {
    year: 2025,
    month: 12,
  });
  assert.deepEqual(shiftMonth({ year: 2026, month: 11 }, 14), {
    year: 2028,
    month: 1,
  });
});

test("a moved week strip marks today only where today falls", () => {
  const today = { year: 2026, month: 11, day: 19 };
  const later = weekStrip({ year: 2026, month: 11, day: 26 }, 3, today);
  assert.deepEqual(later.map((d) => d.today), [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ]);
  const near = weekStrip({ year: 2026, month: 11, day: 21 }, 3, today);
  assert.deepEqual(near.map((d) => d.day), [18, 19, 20, 21, 22, 23, 24]);
  assert.deepEqual(near.map((d) => d.today), [
    false,
    true,
    false,
    false,
    false,
    false,
    false,
  ]);
});
