import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runProbe } from "./pam-fixture.mjs";

test("the lock listens for a finger only while the switch is on", () => {
  // The switch is saved: keep it away from the real state dir.
  const dir = mkdtempSync(join(tmpdir(), "notch-lock-security-"));
  try {
    const result = runProbe("lock-security-switch", {
      XDG_STATE_HOME: dir,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
        .href,
    });
    const log = result.stdout + result.stderr;
    assert.equal(result.status, 0, log);
    assert.match(log, /lock security switch: on true, off false/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
