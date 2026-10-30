import { test } from "node:test";
import assert from "node:assert/strict";
import {
  clock,
  formatPercent,
  parseUptime,
  shortDate,
} from "../shell/logic/format.mjs";

const MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

for (
  const [h, m, text] of [
    [14, 32, "14:32"],
    [0, 5, "00:05"],
    [9, 0, "09:00"],
    [23, 59, "23:59"],
  ]
) {
  test(`clock ${h}:${m} -> ${text}`, () => {
    assert.equal(clock(h, m), text);
  });
}

test("shortDate uses caller-provided month names, no padding", () => {
  assert.equal(shortDate(3, 20, MONTHS), "Mar 20");
  assert.equal(shortDate(12, 5, MONTHS), "Dec 5");
});

test("shortDate follows the names it is given", () => {
  assert.equal(shortDate(3, 20, ["", "", "Mar."]), "Mar. 20");
});

for (
  const [value, text] of [[72.4, "72%"], [71.6, "72%"], [100, "100%"], [
    0,
    "0%",
  ]]
) {
  test(`formatPercent ${value} -> ${text}`, () => {
    assert.equal(formatPercent(value), text);
  });
}

test("parseUptime reads whole seconds from /proc/uptime", () => {
  assert.equal(parseUptime("11520.37 45678.90\n"), 11520);
  assert.equal(parseUptime("187500.99 1.00"), 187500);
});

for (const text of ["", "garbage", "-5 1"]) {
  test(`parseUptime ${JSON.stringify(text)} -> null`, () => {
    assert.equal(parseUptime(text), null);
  });
}
