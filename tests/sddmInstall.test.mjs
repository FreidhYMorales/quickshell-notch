import { test } from "node:test";
import assert from "node:assert/strict";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readlinkSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../scripts/install-sddm-theme.py", import.meta.url),
);

test("installs a separate theme pointing to shared data without touching the existing theme", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-install-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  mkdirSync(join(themes, "silent"));
  writeFileSync(join(themes, "silent", "keep"), "old");
  writeFileSync(join(data, "theme.conf.user"), "[General]\naccent=#123456\n");
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const theme = join(themes, "notch-lock");
  assert.equal(readFileSync(join(themes, "silent", "keep"), "utf8"), "old");
  assert.equal(
    readlinkSync(join(theme, "theme.conf.user")),
    join(data, "theme.conf.user"),
  );
  assert.ok(existsSync(join(theme, "Main.qml")));
  assert.ok(existsSync(join(theme, "metadata.desktop")));
  assert.match(
    readFileSync(join(theme, "metadata.desktop"), "utf8"),
    /^QtVersion=6$/m,
  );
  assert.ok(existsSync(join(theme, "icons", "rotate-ccw.svg")));
  for (const name of ["keyboard.svg", "power.svg", "chevron-left.svg"]) {
    assert.ok(existsSync(join(theme, "icons", name)));
  }
});

test("refuses to overwrite an existing theme", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-install-existing-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  mkdirSync(join(themes, "notch-lock"));
  writeFileSync(join(themes, "notch-lock", "keep"), "untouched");
  writeFileSync(join(data, "theme.conf.user"), "[General]\n");
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /file exists/i);
  assert.equal(
    readFileSync(join(themes, "notch-lock", "keep"), "utf8"),
    "untouched",
  );
});

test("does not create a theme when shared configuration is missing", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-install-missing-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  const result = spawnSync("python3", [script, themes, data], {
    encoding: "utf8",
  });
  assert.notEqual(result.status, 0);
  assert.equal(existsSync(join(themes, "notch-lock")), false);
});

test("theme directories remain traversable with a restrictive umask", () => {
  const base = mkdtempSync("/tmp/opencode/sddm-install-umask-");
  const themes = join(base, "themes");
  const data = join(base, "data");
  mkdirSync(themes);
  mkdirSync(data);
  writeFileSync(join(data, "theme.conf.user"), "[General]\n");
  const wrapper =
    "import os,sys; os.umask(0o077); os.execv(sys.executable, [sys.executable] + sys.argv[1:])";
  const result = spawnSync("python3", ["-c", wrapper, script, themes, data], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  for (
    const path of [
      join(themes, "notch-lock"),
      join(themes, "notch-lock", "icons"),
    ]
  ) {
    assert.equal(statSync(path).mode & 0o777, 0o755);
  }
});
