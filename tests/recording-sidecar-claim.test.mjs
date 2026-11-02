import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("sidecar claim refuses existing files and creates a free target", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-sidecar-claim-");
  try {
    const source = join(dir, "owned source");
    const occupied = join(dir, "existing.ts");
    const free = join(dir, "available.ts");
    writeFileSync(source, "owned");
    writeFileSync(occupied, "existing");
    const result = runTrayProbe("./recording-sidecar-claim.qml", {
      CLAIM_SOURCE: source,
      CLAIM_OCCUPIED: occupied,
      CLAIM_FREE: free,
      NOTCH_SERVICES_URL: new URL("../shell/services", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /sidecar claim: refused then reserved/,
    );
    assert.equal(readFileSync(occupied, "utf8"), "existing");
    assert.equal(readFileSync(source, "utf8"), "owned");
    assert.equal(readFileSync(free, "utf8"), "owned");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
