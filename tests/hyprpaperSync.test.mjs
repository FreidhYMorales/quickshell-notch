import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../shell/scripts/hyprpaper-sync.py", import.meta.url),
);

test("writes a startup config for the saved image", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-hyprpaper-"));
  const image = join(dir, "background.png");
  writeFileSync(image, "image");
  const result = spawnSync("python3", [
    script,
    dir,
    JSON.stringify({ fallback: image, perScreen: {} }),
  ], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.match(
    readFileSync(join(dir, "hyprpaper.conf"), "utf8"),
    /background\.png/,
  );
});

test("preserves the previous config when the wallpaper is missing", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-hyprpaper-"));
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "hyprpaper.conf"), "previous");
  const result = spawnSync("python3", [
    script,
    dir,
    JSON.stringify({ fallback: join(dir, "missing.png"), perScreen: {} }),
  ]);
  assert.notEqual(result.status, 0);
  assert.equal(readFileSync(join(dir, "hyprpaper.conf"), "utf8"), "previous");
});

test("extracts a still frame for animated wallpapers", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-hyprpaper-"));
  const gif = join(dir, "loop.gif");
  writeFileSync(
    gif,
    Buffer.from(
      "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7",
      "base64",
    ),
  );
  const bin = join(dir, "bin");
  mkdirSync(bin);
  writeFileSync(
    join(bin, "ffmpeg"),
    '#!/bin/sh\nfor arg do output="$arg"; done\nprintf frame > "$output"\n',
    { mode: 0o755 },
  );
  const result = spawnSync("python3", [
    script,
    dir,
    JSON.stringify({ fallback: gif, perScreen: {} }),
  ], {
    encoding: "utf8",
    env: { ...process.env, PATH: `${bin}:${process.env.PATH}` },
  });
  assert.equal(result.status, 0, result.stderr);
  const config = readFileSync(join(dir, "hyprpaper.conf"), "utf8");
  assert.match(config, /hyprpaper-frames\/.*\.png/);
});
