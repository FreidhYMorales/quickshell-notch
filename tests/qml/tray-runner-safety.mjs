import { test } from "node:test";
import assert from "node:assert/strict";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { runTrayProbe } from "./run-tray.mjs";

test("tray runner disables crash relaunch for its test config", () => {
  const dir = mkdtempSync(join(tmpdir(), "tray-runner-"));
  try {
    const fakeQs = join(dir, "qs");
    writeFileSync(
      fakeQs,
      `#!/usr/bin/node
console.log("CRASH_HANDLER=" + (process.env.QS_DISABLE_CRASH_HANDLER || ""));
console.log("ARGS=" + process.argv.slice(2).join(" "));
`,
    );
    chmodSync(fakeQs, 0o755);
    const result = runTrayProbe("./tray-menu-entry.qml", {
      PATH: dir + ":" + process.env.PATH,
      QS_DISABLE_CRASH_HANDLER: "",
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /CRASH_HANDLER=1/);
    assert.match(output, /ARGS=-p .*\/tests\/qml\/tray-menu-entry\.qml/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
