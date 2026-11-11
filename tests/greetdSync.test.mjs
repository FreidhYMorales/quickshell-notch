import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import {
  chmodSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  readlinkSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(
  new URL("../shell/scripts/greetd-sync.py", import.meta.url),
);
const palette = (accent, foreground = "#abcdef") =>
  JSON.stringify({
    colors: { primary: { hex: accent }, on_surface: { hex: foreground } },
  });
const run = (image, colors, output) =>
  spawnSync("python3", [script, image, colors, output], { encoding: "utf8" });
const manifest = (output) =>
  JSON.parse(readFileSync(join(output, "visual.json"), "utf8"));

test("publishes immutable wallpaper and palette as one manifest, retaining previous generations", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-"));
  const output = join(dir, "output");
  const image = join(dir, "wallpaper.png");
  mkdirSync(output);
  writeFileSync(image, "first image");
  let result = run(image, palette("#123456"), output);
  assert.equal(result.status, 0, result.stderr);
  const first = manifest(output);
  assert.equal(first.accent, "#123456");
  assert.equal(first.foreground, "#abcdef");
  assert.match(first.background, /^background-[a-f0-9]{64}\.png$/);
  assert.equal(
    readFileSync(join(output, first.background), "utf8"),
    "first image",
  );
  assert.equal(statSync(join(output, first.background)).mode & 0o777, 0o640);
  assert.equal(statSync(join(output, "visual.json")).mode & 0o777, 0o640);
  writeFileSync(image, "second image");
  result = run(image, palette("#654321"), output);
  assert.equal(result.status, 0, result.stderr);
  const second = manifest(output);
  assert.equal(second.accent, "#654321");
  assert.notEqual(second.background, first.background);
  assert.equal(
    readFileSync(join(output, second.background), "utf8"),
    "second image",
  );
  assert.equal(
    readFileSync(join(output, first.background), "utf8"),
    "first image",
  );
  assert.ok(!readFileSync(join(output, "visual.json"), "utf8").includes(dir));
});

test("concurrent publishers serialize and leave a complete matching snapshot", async () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-concurrent-"));
  const output = join(dir, "output");
  const first = join(dir, "first.png");
  const second = join(dir, "second.png");
  mkdirSync(output);
  writeFileSync(first, "first");
  writeFileSync(second, "second");
  const launch = (image, colour) =>
    new Promise((resolve, reject) => {
      const child = spawn("python3", [script, image, palette(colour), output]);
      child.once("error", reject);
      child.once("exit", resolve);
    });
  assert.deepEqual(
    await Promise.all([launch(first, "#111111"), launch(second, "#222222")]),
    [0, 0],
  );
  const value = manifest(output);
  const image = readFileSync(join(output, value.background), "utf8");
  assert.ok(
    (image === "first" && value.accent === "#111111") ||
      (image === "second" && value.accent === "#222222"),
  );
});

test("invalid input and publication failure leave the previous manifest and image intact", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-fail-"));
  const output = join(dir, "output");
  const image = join(dir, "image.png");
  mkdirSync(output);
  writeFileSync(image, "original");
  assert.equal(run(image, palette("#123456"), output).status, 0);
  const before = readFileSync(join(output, "visual.json"), "utf8");
  const original = manifest(output).background;
  writeFileSync(image, "updated");
  assert.notEqual(run(image, palette("bad"), output).status, 0);
  assert.equal(readFileSync(join(output, "visual.json"), "utf8"), before);
  assert.equal(readFileSync(join(output, original), "utf8"), "original");
  const blocked = join(dir, "blocked");
  mkdirSync(blocked);
  mkdirSync(join(blocked, "visual.json"));
  assert.notEqual(run(image, palette("#654321"), blocked).status, 0);
  assert.equal(readFileSync(join(output, "visual.json"), "utf8"), before);
  assert.ok(!readdirSync(blocked).some((name) => name.startsWith(".stage-")));
});

test("an unsafe existing content-addressed target is never followed or overwritten", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-link-"));
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  mkdirSync(output);
  writeFileSync(image, "image");
  assert.equal(run(image, palette("#123456"), output).status, 0);
  const name = manifest(output).background;
  const target = join(dir, "target");
  writeFileSync(target, "untouched");
  const replace = spawnSync("python3", [
    "-c",
    "import os,sys; os.unlink(sys.argv[1]); os.symlink(sys.argv[2], sys.argv[1])",
    join(output, name),
    target,
  ]);
  assert.equal(replace.status, 0);
  const before = readFileSync(join(output, "visual.json"), "utf8");
  assert.notEqual(run(image, palette("#654321"), output).status, 0);
  assert.equal(readFileSync(target, "utf8"), "untouched");
  assert.equal(readFileSync(join(output, "visual.json"), "utf8"), before);
});

test("a symlink manifest is rejected without touching its target", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-manifest-link-"));
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  const target = join(dir, "outside");
  mkdirSync(output);
  writeFileSync(image, "image");
  writeFileSync(target, "untouched");
  symlinkSync(target, join(output, "visual.json"));
  assert.notEqual(run(image, palette("#123456"), output).status, 0);
  assert.equal(readFileSync(target, "utf8"), "untouched");
});

test("requires a pre-existing private writable output and rejects symlink targets and locks", () => {
  const dir = mkdtempSync(join(tmpdir(), "greetd-sync-path-"));
  const image = join(dir, "image.png");
  const output = join(dir, "output");
  writeFileSync(image, "image");
  assert.notEqual(run(image, palette("#123456"), output).status, 0);
  mkdirSync(output, { mode: 0o770 });
  chmodSync(output, 0o770);
  assert.notEqual(run(image, palette("#123456"), output).status, 0);
  chmodSync(output, 0o750);
  const link = join(dir, "link");
  symlinkSync(output, link);
  assert.notEqual(run(image, palette("#123456"), link).status, 0);
  assert.notEqual(
    run(image, palette("#123456"), `${link}/../output`).status,
    0,
  );
  symlinkSync(image, join(output, ".publish.lock"));
  assert.notEqual(run(image, palette("#123456"), output).status, 0);
  assert.equal(readlinkSync(join(output, ".publish.lock")), image);
  assert.equal(readFileSync(image, "utf8"), "image");
});
