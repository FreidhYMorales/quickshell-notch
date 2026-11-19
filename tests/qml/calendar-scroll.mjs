import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

test("scrolling moves weeks and months and the clock and title jump back to today", () => {
  mkdirSync("/tmp/opencode", { recursive: true });
  const dir = mkdtempSync("/tmp/opencode/notch-calendar-scroll-");
  try {
    const now = new Date();
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./calendar-scroll.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: join(dir, "state"),
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    const later = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + 7,
    );
    const next = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const title = MONTHS[now.getMonth()] + " " + now.getFullYear();
    const nextTitle = MONTHS[next.getMonth()] + " " + next.getFullYear();
    assert.match(
      output,
      new RegExp(
        "calendar scroll: week " + now.getDate() + " > " + later.getDate() +
          " > " + now.getDate() + "; month " + nextTitle + " > " + title,
      ),
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
