import { test } from "node:test";
import assert from "node:assert/strict";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/sddm-theme-switch.py", import.meta.url),
);

test("activation and recovery preserve the original configuration", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-switch-");
  const old = join(dir, "deadlock.conf");
  const override = join(dir, "zz-notch-lock.conf");
  writeFileSync(old, "[Theme]\nCurrent=silent\n");
  const run = (action) =>
    spawnSync("python3", [script, action, dir], { encoding: "utf8" });
  assert.equal(run("activate").status, 0);
  assert.equal(readFileSync(old, "utf8"), "[Theme]\nCurrent=silent\n");
  assert.equal(readFileSync(override, "utf8"), "[Theme]\nCurrent=notch-lock\n");
  assert.equal(run("restore").status, 0);
  assert.equal(existsSync(override), false);
  assert.equal(readFileSync(old, "utf8"), "[Theme]\nCurrent=silent\n");
  assert.deepEqual(readdirSync(dir), ["deadlock.conf"]);
  assert.equal(
    readFileSync(join(dir + "-notch-backups", "zz-notch-lock.conf"), "utf8"),
    "[Theme]\nCurrent=notch-lock\n",
  );
});

test("restore refuses to overwrite a previous backup and preserves the active override", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-switch-backup-");
  const run = (action) =>
    spawnSync("python3", [script, action, dir], { encoding: "utf8" });
  assert.equal(run("activate").status, 0);
  mkdirSync(dir + "-notch-backups");
  const backup = join(dir + "-notch-backups", "zz-notch-lock.conf");
  writeFileSync(backup, "keep\n");
  assert.notEqual(run("restore").status, 0);
  assert.equal(readFileSync(backup, "utf8"), "keep\n");
  assert.equal(
    readFileSync(join(dir, "zz-notch-lock.conf"), "utf8"),
    "[Theme]\nCurrent=notch-lock\n",
  );
});

test("refuses to replace or disable a foreign override", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-switch-existing-");
  const override = join(dir, "zz-notch-lock.conf");
  writeFileSync(override, "custom content\n");
  for (const action of ["activate", "restore"]) {
    const result = spawnSync("python3", [script, action, dir], {
      encoding: "utf8",
    });
    assert.notEqual(result.status, 0);
    assert.equal(readFileSync(override, "utf8"), "custom content\n");
  }
});
