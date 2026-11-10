import { test } from "node:test";
import assert from "node:assert/strict";
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readlinkSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/update-sddm-theme.py", import.meta.url),
);

test("updates notch-lock while preserving the old theme and silent", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-update-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  const old = join(themes, "notch-lock");
  mkdirSync(themes);
  mkdirSync(data);
  mkdirSync(old);
  mkdirSync(join(themes, "silent"));
  writeFileSync(join(data, "theme.conf.user"), "[General]\n");
  writeFileSync(join(old, "Main.qml"), "old theme");
  symlinkSync(join(data, "theme.conf.user"), join(old, "theme.conf.user"));
  writeFileSync(join(themes, "silent", "keep"), "silent");
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(
    readFileSync(
      join(themes, "notch-lock-backup", "notch-lock", "Main.qml"),
      "utf8",
    ),
    "old theme",
  );
  assert.match(
    readFileSync(join(old, "Main.qml"), "utf8"),
    /keyboardRequested/,
  );
  assert.equal(
    readlinkSync(join(old, "theme.conf.user")),
    join(data, "theme.conf.user"),
  );
  assert.equal(readFileSync(join(themes, "silent", "keep"), "utf8"), "silent");
});

test("refuses to overwrite an existing backup", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-update-existing-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  mkdirSync(join(themes, "notch-lock"));
  mkdirSync(join(themes, "notch-lock-backup"));
  writeFileSync(join(data, "theme.conf.user"), "[General]\n");
  writeFileSync(join(themes, "notch-lock", "keep"), "old");
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /backup already exists/);
  assert.equal(readFileSync(join(themes, "notch-lock", "keep"), "utf8"), "old");
});

test("refuses a different shared configuration link", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-update-link-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  mkdirSync(join(themes, "notch-lock"));
  symlinkSync(
    "/different/config",
    join(themes, "notch-lock", "theme.conf.user"),
  );
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /configuration link differs/);
  assert.equal(
    readlinkSync(join(themes, "notch-lock", "theme.conf.user")),
    "/different/config",
  );
});
