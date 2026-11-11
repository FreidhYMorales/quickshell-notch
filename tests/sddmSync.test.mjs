import { test } from "node:test";
import assert from "node:assert/strict";
import {
  chmodSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../shell/scripts/sddm-sync.py", import.meta.url),
);
const backgroundOf = (config) =>
  fileURLToPath(config.match(/^background=(.+)$/m)[1]);

test("publication waits for another publisher holding the directory lock", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-lock-");
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  mkdirSync(output);
  writeFileSync(image, "image");
  const palette = JSON.stringify({
    colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
  });
  const probe =
    `import fcntl, os, subprocess, sys\nlock = open(os.path.join(sys.argv[1], '.publish.lock'), 'w')\nfcntl.flock(lock, fcntl.LOCK_EX)\ntry:\n subprocess.run(sys.argv[2:], timeout=0.5, check=True)\n sys.exit(1)\nexcept subprocess.TimeoutExpired:\n sys.exit(0)\n`;
  const result = spawnSync("python3", [
    "-c",
    probe,
    output,
    "python3",
    script,
    image,
    palette,
    output,
  ], { encoding: "utf8", timeout: 5000 });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readdirSync(output).includes("theme.conf.user"), false);
});

test("publication retains group-readable modes in a setgid directory", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-group-");
  const image = join(dir, "image.png");
  const output = join(dir, "data");
  mkdirSync(output);
  chmodSync(output, 0o2750);
  writeFileSync(image, "image");
  const palette = JSON.stringify({
    colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
  });
  const result = spawnSync("python3", [script, image, palette, output], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const configPath = join(output, "theme.conf.user");
  const background = backgroundOf(readFileSync(configPath, "utf8"));
  for (const path of [configPath, background]) {
    assert.equal(statSync(path).gid, statSync(output).gid);
    assert.equal(statSync(path).mode & 0o777, 0o640);
  }
});

test("staged background and config are not readable by other users", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-mode-");
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  const palette = JSON.stringify({
    colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
  });
  writeFileSync(image, "image");
  const result = spawnSync("python3", [script, image, palette, output], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const configPath = join(output, "theme.conf.user");
  const config = readFileSync(configPath, "utf8");
  for (const path of [configPath, backgroundOf(config)]) {
    assert.equal(statSync(path).mode & 0o777, 0o640);
  }
});

test("reapplying a previously world-readable image publishes a restricted slot", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-migrate-");
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  const palette = JSON.stringify({
    colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
  });
  writeFileSync(image, "image");
  const run = () =>
    spawnSync("python3", [script, image, palette, output], {
      encoding: "utf8",
    });
  assert.equal(run().status, 0);
  const configPath = join(output, "theme.conf.user");
  const oldConfig = readFileSync(configPath, "utf8");
  chmodSync(backgroundOf(oldConfig), 0o644);
  assert.equal(run().status, 0);
  const newConfig = readFileSync(configPath, "utf8");
  assert.notEqual(backgroundOf(newConfig), backgroundOf(oldConfig));
  assert.equal(statSync(backgroundOf(newConfig)).mode & 0o777, 0o640);
  assert.equal(readFileSync(backgroundOf(oldConfig), "utf8"), "image");
});

test("stages an image and palette for the greeter without system changes", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-");
  const image = join(dir, "wall paper.png");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(image, "image bytes");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const result = spawnSync("python3", [script, image, palette, output], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const config = readFileSync(join(output, "theme.conf.user"), "utf8");
  assert.match(config, /accent=#123456/);
  assert.match(config, /foreground=#abcdef/);
  assert.match(config, /^sourceWallpaper=file:/m);
  assert.equal(
    readFileSync(backgroundOf(config), "utf8"),
    "image bytes",
  );
});

test("invalid palette leaves the last staged files unchanged", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-invalid-");
  const image = join(dir, "image.png");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(image, "first image");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const run = () =>
    spawnSync("python3", [script, image, palette, output], {
      encoding: "utf8",
    });
  assert.equal(run().status, 0);
  const previous = readFileSync(join(output, "theme.conf.user"), "utf8");
  writeFileSync(image, "second image");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "invalid" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  assert.notEqual(run().status, 0);
  assert.equal(readFileSync(join(output, "theme.conf.user"), "utf8"), previous);
  assert.equal(
    readFileSync(backgroundOf(previous), "utf8"),
    "first image",
  );
});

test("a newer publication never overwrites the previous background", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-atomic-");
  const image = join(dir, "image.png");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const run = () =>
    spawnSync("python3", [script, image, palette, output], {
      encoding: "utf8",
    });
  writeFileSync(image, "old");
  assert.equal(run().status, 0);
  const oldConfig = readFileSync(join(output, "theme.conf.user"), "utf8");
  writeFileSync(image, "new");
  assert.equal(run().status, 0);
  const newConfig = readFileSync(join(output, "theme.conf.user"), "utf8");
  assert.notEqual(backgroundOf(oldConfig), backgroundOf(newConfig));
  assert.equal(readFileSync(backgroundOf(oldConfig), "utf8"), "old");
  assert.equal(readFileSync(backgroundOf(newConfig), "utf8"), "new");
});

test("reapplying the same image does not accumulate copies", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-repeat-");
  const image = join(dir, "image.png");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(image, "same image");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const run = () =>
    spawnSync("python3", [script, image, palette, output], {
      encoding: "utf8",
    });
  assert.equal(run().status, 0);
  assert.equal(run().status, 0);
  assert.equal(
    readdirSync(output).filter((name) => name.startsWith("background-")).length,
    1,
  );
});

test("three different backgrounds reuse two slots", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-sync-slots-");
  const image = join(dir, "image.png");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const run = () =>
    spawnSync("python3", [script, image, palette, output], {
      encoding: "utf8",
    });
  for (const data of ["first", "second", "third"]) {
    writeFileSync(image, data);
    assert.equal(run().status, 0);
  }
  assert.equal(
    readdirSync(output).filter((name) => name.startsWith("background-")).length,
    2,
  );
  const config = readFileSync(join(output, "theme.conf.user"), "utf8");
  assert.equal(readFileSync(backgroundOf(config), "utf8"), "third");
});

test("stages a video itself instead of a still", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-video-");
  const video = join(dir, "background.mp4");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  writeFileSync(video, "video data");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  const result = spawnSync("python3", [script, video, palette, output], {
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const config = readFileSync(join(output, "theme.conf.user"), "utf8");
  assert.match(config, /^mediaKind=video$/m);
  assert.equal(readFileSync(backgroundOf(config), "utf8"), "video data");
});

test("converts a GIF to a video for the greeter", () => {
  const dir = mkdtempSync("/tmp/opencode/sddm-gif-");
  const gif = join(dir, "background.gif");
  const palette = join(dir, "colors.json");
  const output = join(dir, "output");
  const bin = join(dir, "bin");
  mkdirSync(bin);
  writeFileSync(gif, "gif data");
  writeFileSync(
    palette,
    JSON.stringify({
      colors: { primary: { hex: "#123456" }, on_surface: { hex: "#abcdef" } },
    }),
  );
  writeFileSync(
    join(bin, "ffmpeg"),
    '#!/bin/sh\nfor arg do out=$arg; done\nprintf converted > "$out"\n',
    { mode: 0o755 },
  );
  const result = spawnSync("python3", [script, gif, palette, output], {
    encoding: "utf8",
    env: Object.assign({}, process.env, { PATH: `${bin}:${process.env.PATH}` }),
  });
  assert.equal(result.status, 0, result.stderr);
  const config = readFileSync(join(output, "theme.conf.user"), "utf8");
  assert.match(config, /^mediaKind=video$/m);
  assert.equal(readFileSync(backgroundOf(config), "utf8"), "converted");
});
