import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./power-cc-hold.qml", import.meta.url));

const menuLine = (output, icon) => {
  const match = new RegExp(`cc hold: ${icon} open (\\w+) menu (.*) on (\\S+)`)
    .exec(output);
  assert.ok(match, output);
  return { open: match[1], menu: JSON.parse(match[2]), monitor: match[3] };
};

test("control center session actions open the power menu preselected", () => {
  // Fake binaries first on PATH: a broken dry run only leaves a marker file.
  const dir = mkdtempSync(join(tmpdir(), "notch-power-cc-hold-"));
  const called = join(dir, "called");
  for (const bin of ["systemctl", "hyprctl"]) {
    writeFileSync(join(dir, bin), `#!/bin/sh\necho "$0 $*" >> "${called}"\n`, {
      mode: 0o755,
    });
  }
  try {
    const result = spawnSync("qs", ["-p", probe], {
      encoding: "utf8",
      timeout: 15000,
      env: Object.assign({}, process.env, {
        PATH: `${dir}:${process.env.PATH}`,
        NOTCH_SMOKE: "1",
        NOTCH_CC_URL:
          new URL("../../shell/notches/controlcenter", import.meta.url).href,
        NOTCH_CENTER_URL:
          new URL("../../shell/notches/center", import.meta.url).href,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.equal(existsSync(called), false, "a power command was executed");
    assert.doesNotMatch(output, /power: dry run/);
    const reboot = menuLine(output, "󰜉");
    assert.equal(reboot.open, "false");
    assert.deepEqual(reboot.menu, {
      owner: reboot.monitor,
      kind: "power",
      sub: "reboot",
      hold: null,
    });
    const poweroff = menuLine(output, "⏻");
    assert.equal(poweroff.open, "false");
    assert.equal(poweroff.menu.sub, "poweroff");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
