import { test } from "node:test";
import assert from "node:assert/strict";
import { clock, shortDate } from "../shell/logic/format.mjs";

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
