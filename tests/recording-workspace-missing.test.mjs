import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("missing workspace creator reports failure", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-workspace-missing-");
  try {
    for (
      const name of ["dbus-run-session", "dbus-daemon", "sh", "python3", "qs"]
    ) {
      symlinkSync(`/usr/bin/${name}`, join(dir, name));
    }
    const result = runTrayProbe("./recording-workspace-failure.qml", {
      PATH: dir,
      WORKSPACE_PARENT: dir,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /workspace failure: rejected/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
