import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("refuses to launch the client when the private socket is missing", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-no-socket-"));
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    writeFileSync(join(dir, "pkg-config"), "#!/bin/sh\nexit 0\n", {
      mode: 0o755,
    });
    writeFileSync(
      join(dir, "cc"),
      `#!/bin/sh
while [ "$1" != "-o" ]; do shift; done
shift
/bin/cp "$FIXTURE_DIR/server-fixture" "$1"
/bin/chmod +x "$1"
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "server-fixture"),
      `#!${process.execPath}
console.log("isolated: ready");
setInterval(() => {}, 1000);
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "qs"),
      `#!${process.execPath}
require("node:fs").writeFileSync(${
        JSON.stringify(join(dir, "client-started"))
      }, "");
console.log("isolated: secure");
`,
      { mode: 0o755 },
    );
    const result = spawnSync(process.execPath, [runner], {
      env: { PATH: dir, TMPDIR: dir, FIXTURE_DIR: dir },
      encoding: "utf8",
      timeout: 8000,
    });
    assert.notEqual(result.status, 0, result.stdout);
    assert.match(result.stderr, /unsafe isolated socket/i);
    assert.equal(existsSync(join(dir, "client-started")), false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
