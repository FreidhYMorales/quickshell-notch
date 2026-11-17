import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));

function dryRun(target) {
  const run = spawnSync("make", ["-n", target], {
    cwd: root,
    encoding: "utf8",
  });
  return { status: run.status, out: run.stdout + run.stderr };
}

test("check-fast runs only the format check and the lint", () => {
  const { status, out } = dryRun("check-fast");
  assert.equal(status, 0, out);
  assert.match(out, /qmlformat/);
  assert.match(out, /deno fmt --check/);
  assert.match(out, /qmllint/);
  assert.match(out, /deno lint/);
  assert.doesNotMatch(out, /node --test/);
  assert.doesNotMatch(out, /\bqs -p\b/);
  assert.doesNotMatch(out, /smoke/);
});
