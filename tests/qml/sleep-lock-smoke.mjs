import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { fakeTools } from "./sleep-fixture.mjs";

test("a smoke run starts neither the logind monitor nor the inhibitor", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-sleep-smoke-"));
  try {
    const log = fakeTools(dir);
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./sleep-lock-smoke.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        PATH: dir + ":" + process.env.PATH,
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL: new URL("../../shell/services", import.meta.url)
          .href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.match(output, /sleep lock smoke: inhibit true/, output);
    assert.equal(existsSync(log), false, "a sleep process ran under smoke");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
