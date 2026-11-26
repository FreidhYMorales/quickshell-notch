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
      : [];
    assert.ok(
      events.some((line) => line.includes("--mode=block")),
      "sleep stays blocked until logind state is verified\n" + output,
    );
    assert.ok(
      events.some((line) =>
        line.startsWith("inhibit stop") && line.includes("--mode=block")
      ),
      "the fail-safe blocker is released after verification\n" + output,
    );
    assert.ok(
      events.some((line) => line.includes("--mode=delay")),
      "the normal delay inhibitor remains active\n" + output,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("a failed logind monitor retries while sleep remains blocked", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-sleep-lock-retry-"));
  try {
    const log = fakeTools(dir, true);
    const result = runProbe(dir, false);
    const output = result.stdout + result.stderr;
    assert.match(output, /logind monitor exited with 1/, output);
    assert.match(output, /sleep lock: lock requested/, output);
    const events = existsSync(log)
      ? readFileSync(log, "utf8").trim().split("\n")
      : [];
    assert.ok(
      events.filter((line) => line.includes("gdbus monitor")).length >= 2,
      "monitor should restart after its first failure\n" + output,
    );
    assert.ok(
      events.some((line) => line.includes("--mode=block")),
      "sleep should be blocked during monitor recovery\n" + output,
    );
    assert.ok(
      events.some((line) =>
        line.startsWith("inhibit stop") && line.includes("--mode=block")
      ),
      "sleep blocker should release after monitor state is verified\n" + output,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
