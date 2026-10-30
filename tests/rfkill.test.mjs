import { test } from "node:test";
import assert from "node:assert/strict";
import {
  applyRfkillEvent,
  parseRfkillEvent,
  wifiOn,
} from "../shell/logic/rfkill.mjs";

test("parseRfkillEvent reads a wlan add line", () => {
  assert.deepEqual(
    parseRfkillEvent(
      "2026-10-30 13:02:47,762279-06:00: idx 2 type 1 op 0 soft 0 hard 0",
    ),
    { idx: 2, type: "wlan", op: "add", soft: false, hard: false },
  );
});

test("parseRfkillEvent reads a bluetooth change with a soft block", () => {
  assert.deepEqual(
    parseRfkillEvent(
      "2026-10-30 13:05:00,000001-06:00: idx 1 type 2 op 2 soft 1 hard 0",
    ),
    { idx: 1, type: "bluetooth", op: "change", soft: true, hard: false },
  );
});

test("parseRfkillEvent reads a delete with a hard block", () => {
  assert.deepEqual(
    parseRfkillEvent(
      "2026-10-30 13:05:00,000001-06:00: idx 3 type 1 op 1 soft 0 hard 1",
    ),
    { idx: 3, type: "wlan", op: "del", soft: false, hard: true },
  );
});

for (const line of ["", "garbage", "idx x type 1 op 0 soft 0 hard 0"]) {
  test(`parseRfkillEvent ${JSON.stringify(line)} -> null`, () => {
    assert.equal(parseRfkillEvent(line), null);
  });
}

const ev = (idx, type, op, soft, hard) => ({ idx, type, op, soft, hard });
const replay = (events) => events.reduce(applyRfkillEvent, {});

test("wifiOn: an unblocked wlan is on", () => {
  assert.equal(wifiOn(replay([ev(2, "wlan", "add", false, false)])), true);
});

test("wifiOn: a soft block after the add turns it off", () => {
  assert.equal(
    wifiOn(replay([
      ev(2, "wlan", "add", false, false),
      ev(2, "wlan", "change", true, false),
    ])),
    false,
  );
});

test("wifiOn: a hard-blocked wlan is off", () => {
  assert.equal(wifiOn(replay([ev(2, "wlan", "add", false, true)])), false);
});

test("wifiOn: one unblocked wlan among blocked ones is on", () => {
  assert.equal(
    wifiOn(replay([
      ev(2, "wlan", "add", true, false),
      ev(4, "wlan", "add", false, false),
    ])),
    true,
  );
});

test("wifiOn: a deleted wlan leaves no WiFi", () => {
  assert.equal(
    wifiOn(replay([
      ev(2, "wlan", "add", false, false),
      ev(2, "wlan", "del", false, false),
    ])),
    null,
  );
});

test("wifiOn: bluetooth radios alone are no WiFi", () => {
  assert.equal(
    wifiOn(replay([
      ev(0, "bluetooth", "add", false, false),
      ev(1, "bluetooth", "add", false, false),
    ])),
    null,
  );
});
