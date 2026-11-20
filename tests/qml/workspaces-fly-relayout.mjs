import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("the flight starts at the source slot and the destination stays empty until it lands, while the strip is rebuilt", () => {
  mkdirSync("/tmp/opencode", { recursive: true });
  const dir = mkdtempSync("/tmp/opencode/notch-workspaces-relayout-");
  try {
    const result = spawnSync("qs", [
      "-p",
      fileURLToPath(new URL("./workspaces-fly-relayout.qml", import.meta.url)),
    ], {
      encoding: "utf8",
      timeout: 20000,
      env: Object.assign({}, process.env, {
        XDG_STATE_HOME: join(dir, "state"),
        NOTCH_SMOKE: "1",
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
        NOTCH_SERVICES_URL:
          new URL("../../shell/services", import.meta.url).href,
        NOTCH_WORKSPACES_URL:
          new URL("../../shell/notches/workspaces", import.meta.url).href,
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(
      output,
      /workspaces relayout: start at source; destination empty; after gone, destination shown/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
