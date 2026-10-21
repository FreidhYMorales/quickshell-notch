import test from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";

// Qt's V4 engine (which loads shell/logic/*.mjs) rejects object spread.
// Node accepts it, so this guard fails before Quickshell does.
const dir = new URL("../shell/logic/", import.meta.url);

test("shell/logic has no object spread (unsupported by Qt V4)", () => {
  const offenders = [];
  for (const file of readdirSync(dir)) {
    if (!file.endsWith(".mjs")) continue;
    const lines = readFileSync(new URL(file, dir), "utf8").split("\n");
    lines.forEach((line, i) => {
      if (/^\s*\/\//.test(line)) return;
      if (/(\{\s*|^\s*)\.\.\.[\w(]/.test(line)) {
        offenders.push(`${file}:${i + 1}: ${line.trim()}`);
      }
    });
  }
  assert.deepEqual(offenders, []);
});
