import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { createLockStub } from "./lock-stub-fixture.mjs";

test("normal cleanup preserves a replaced runtime", () => {
  const fixture = createLockStub(`
const fs = require("node:fs"), path = require("node:path");
const runtime = process.env.XDG_RUNTIME_DIR;
fs.renameSync(runtime, runtime + ".original");
fs.mkdirSync(runtime, { mode: 0o700 });
fs.writeFileSync(path.join(runtime, "sentinel"), "keep");
console.log("isolated: secure");
`);
  try {
    const result = fixture.run();
    assert.equal(result.status, 0, result.stderr);
    const replacement = readdirSync(fixture.dir).find((name) =>
      name.startsWith("notch-lock-isolated-") && !name.endsWith(".original")
    );
    assert.ok(replacement, "replacement runtime was removed");
    assert.equal(
      readFileSync(join(fixture.dir, replacement, "sentinel"), "utf8"),
      "keep",
    );
  } finally {
    fixture.cleanup();
  }
});
