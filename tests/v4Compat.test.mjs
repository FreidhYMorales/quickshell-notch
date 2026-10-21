import test from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";

// Qt's V4 engine (which loads shell/logic/*.mjs) rejects some syntax and APIs
// that Node accepts, so these guards fail before Quickshell does.
const dir = new URL("../shell/logic/", import.meta.url);

const unsupported = [
  ["object spread", /(\{\s*|^\s*)\.\.\.[\w(]/],
  ["optional catch binding", /\bcatch\s*\{/],
  ["Array.prototype.flatMap", /\.flatMap\s*\(/],
  ["Object.fromEntries", /\bObject\.fromEntries\s*\(/],
];

for (const [name, pattern] of unsupported) {
  test(`shell/logic has no ${name} (unsupported by Qt V4)`, () => {
    const offenders = [];
    for (const file of readdirSync(dir)) {
      if (!file.endsWith(".mjs")) continue;
      const lines = readFileSync(new URL(file, dir), "utf8").split("\n");
      lines.forEach((line, i) => {
        if (/^\s*\/\//.test(line)) return;
        if (pattern.test(line)) {
          offenders.push(`${file}:${i + 1}: ${line.trim()}`);
        }
      });
    }
    assert.deepEqual(offenders, []);
  });
}
