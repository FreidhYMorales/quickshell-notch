import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("workspace failure does not accept a printed path", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-workspace-error-");
  try {
    writeFileSync(
      join(dir, "mktemp"),
      '#!/bin/sh\nprintf "%s\\n" "$FAKE_PATH"\nexit 1\n',
      { mode: 0o755 },
    );
    const result = runTrayProbe("./recording-workspace-failure.qml", {
      PATH: `${dir}:${process.env.PATH}`,
      WORKSPACE_PARENT: dir,
      FAKE_PATH: join(dir, "not-a-workspace"),
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /workspace failure: rejected/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
