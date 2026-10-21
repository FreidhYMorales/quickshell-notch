import { test } from "node:test";
import assert from "node:assert/strict";
import { dayKey, weekStrip } from "../shell/logic/calendar.mjs";

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
