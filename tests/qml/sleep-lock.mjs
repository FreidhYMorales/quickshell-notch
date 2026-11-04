import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fakeTools, runProbe } from "./sleep-fixture.mjs";

test("sleep asks for the lock and the inhibitor is held until the lock is confirmed", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-sleep-lock-"));
  try {
    const log = fakeTools(dir);
    const result = runProbe(dir, false);
    const output = result.stdout + result.stderr;
    assert.match(output, /sleep lock: lock requested/, output);
    const events = existsSync(log)
      ? readFileSync(log, "utf8").trim().split("\n")
        .filter((line) => line.startsWith("inhibit"))
        .map((line) => line.split(" ").slice(0, 2).join(" "))
      : [];
    assert.deepEqual(events, [
      "inhibit start",
      "inhibit stop",
      "inhibit start",
    ], output);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
