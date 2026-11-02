import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("missing directory creator reports failure without starting capture", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-mkdir-missing-");
  try {
    for (
      const name of [
        "dbus-run-session",
        "dbus-daemon",
        "sh",
        "python3",
        "qs",
        "mktemp",
        "ln",
      ]
    ) {
      symlinkSync(`/usr/bin/${name}`, join(dir, name));
    }
    const result = runTrayProbe("./recording-workspace-start-failure.qml", {
      PATH: dir,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /workspace start failure: reported/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
