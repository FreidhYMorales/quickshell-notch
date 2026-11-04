import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdtempSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const hook = fileURLToPath(
  new URL("../system/lock-before-sleep", import.meta.url),
);

test("the sleep hook does nothing after resume (post)", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-sleep-hook-"));
  try {
    const log = join(dir, "called");
    for (const tool of ["runuser", "qs", "timeout"]) {
      writeFileSync(join(dir, tool), `#!/bin/bash\necho ${tool} >> "${log}"\n`);
      chmodSync(join(dir, tool), 0o755);
    }
    const result = spawnSync("bash", [hook, "post", "suspend"], {
      encoding: "utf8",
      timeout: 5000,
      env: Object.assign({}, process.env, {
        PATH: dir + ":" + process.env.PATH,
      }),
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.equal(existsSync(log), false, "the hook ran a command after resume");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
