import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const probe = fileURLToPath(new URL("./power-hold.qml", import.meta.url));
const center = new URL("../../shell/notches/center", import.meta.url).href;

test("a full hold runs its action once; an early release runs nothing", () => {
  // Fake binaries first on PATH: a broken dry run only leaves a marker file.
  const dir = mkdtempSync(join(tmpdir(), "notch-power-hold-"));
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
        NOTCH_CENTER_URL: center,
        QT_QPA_PLATFORM: "wayland",
        NO_COLOR: "1",
        QS_DISABLE_CRASH_HANDLER: "1",
      }),
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.equal(existsSync(called), false, "a power command was executed");
    const [cancel, rest] = output.split("probe: cancel phase done");
    assert.ok(rest, output);
    const [complete] = rest.split("probe: complete phase checked");
    assert.doesNotMatch(cancel, /power: dry run/);
    // 1300ms after the first start, 700ms after the repeat: only a timer the
    // repeat did not restart has fired by now.
    assert.equal(
      complete.match(/power: dry run [^\n]*/g)?.join("|"),
      "power: dry run systemctl poweroff",
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
