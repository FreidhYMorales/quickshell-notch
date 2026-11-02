import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readdirSync, rmSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { runTrayProbe } from "./run-tray.mjs";

test("recording workspace is unique and private", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-workspace-");
  try {
    const result = runTrayProbe("./recording-workspace.qml", {
      WORKSPACE_PARENT: dir,
      NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    const paths = readdirSync(dir).map((name) => join(dir, name));
    assert.equal(paths.length, 2);
    for (const path of paths) {
      assert.equal(dirname(path), dir);
      assert.equal(statSync(path).mode & 0o777, 0o700);
      assert.equal(statSync(path).isDirectory(), true);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
