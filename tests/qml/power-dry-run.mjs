import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./power-dry-run.qml", import.meta.url));
const services = new URL("../../shell/services", import.meta.url).href;

// Fake power commands first on PATH: even a broken dry run cannot touch the
// live session, it only leaves a marker file behind.
const runDry = (env) => {
  const dir = mkdtempSync(join(tmpdir(), "notch-power-"));
  const called = join(dir, "called");
  for (const bin of ["systemctl", "hyprctl", "uwsm"]) {
    writeFileSync(join(dir, bin), `#!/bin/sh\necho "$0 $*" >> "${called}"\n`, {
      mode: 0o755,
    });
  }
  try {
    const result = spawnSync("qs", ["-p", probe], {
      encoding: "utf8",
      timeout: 10000,
      env: Object.assign({}, process.env, {
        PATH: `${dir}:${process.env.PATH}`,
        NOTCH_SERVICES_URL: services,
        QT_QPA_PLATFORM: "offscreen",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
      }, env),
    });
    return {
      output: result.stdout + result.stderr,
      status: result.status,
      ran: existsSync(called),
    };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
};

const expectDryRun = ({ output, status, ran }) => {
  assert.equal(status, 0, output);
  assert.equal(ran, false, "a power command was executed");
  assert.match(output, /power: dry run lock/);
  assert.match(output, /power: dry run systemctl suspend-then-hibernate/);
  assert.match(output, /power: dry run uwsm stop/);
  assert.match(output, /power: dry run systemctl reboot/);
  assert.match(output, /power: dry run systemctl poweroff/);
};

test("dry run flag logs every power action and runs none", () => {
  expectDryRun(runDry({ NOTCH_SMOKE: "0", NOTCH_POWER_DRY_RUN: "1" }));
});

test("smoke runs never execute power actions", () => {
  expectDryRun(runDry({ NOTCH_SMOKE: "1" }));
});
