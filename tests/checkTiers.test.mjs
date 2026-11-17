import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
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

test("check still runs the tests, the QML probes and the smoke", () => {
  const { status, out } = dryRun("check");
  assert.equal(status, 0, out);
  assert.match(out, /node --test tests\/(\n|$)/);
  assert.match(out, /node --test .*tests\/qml\/lock-/);
  assert.match(out, /qs -p shell\/shell\.qml/);
});

const rule =
  "A story, a ship and CI are done when `make check` passes. Between turns the hook runs `check-fast`.";

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
}

test("AGENTS.md teaches both tiers and make fmt as the hook's fix", () => {
  const agents = read("AGENTS.md");
  assert.ok(agents.includes(rule), "AGENTS.md lacks the two-tier rule");
  assert.match(agents, /hook[^.\n]*format[^.\n]*`make fmt`/);
  assert.doesNotMatch(agents, /Stop hook runs it before/);
});
