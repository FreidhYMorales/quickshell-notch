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

test("the month header arrows page to the next and previous month", () => {
  mkdirSync("/tmp/opencode", { recursive: true });
  const dir = mkdtempSync("/tmp/opencode/notch-calendar-arrows-");
  try {
    const now = new Date();
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./calendar-arrows.qml", import.meta.url)),
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
    const at = (delta) => {
      const d = new Date(now.getFullYear(), now.getMonth() + delta, 1);
      return MONTHS[d.getMonth()] + " " + d.getFullYear();
    };
    assert.match(
      output,
      new RegExp(
        "calendar arrows: " + at(0) + " > " + at(1) + " > " + at(-1),
      ),
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
