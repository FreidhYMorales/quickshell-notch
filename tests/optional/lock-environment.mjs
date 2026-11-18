import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

test("the lock probe receives only its private environment", () => {
  const dir = mkdtempSync(join(tmpdir(), "notch-env-probe-"));
  const bin = join(dir, "bin");
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  try {
    mkdirSync(bin);
    writeFileSync(join(bin, "pkg-config"), "#!/bin/sh\nexit 0\n", {
      mode: 0o755,
    });
    writeFileSync(
      join(bin, "cc"),
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
const net = require("node:net");
const path = require("node:path");
net.createServer().listen(
  path.join(process.env.XDG_RUNTIME_DIR, process.env.WAYLAND_DISPLAY),
  () => console.log("isolated: ready"),
);
`,
      { mode: 0o755 },
    );
    writeFileSync(
      join(bin, "qs"),
      `#!${process.execPath}
const bad = ["QT_PLUGIN_PATH", "XDG_CONFIG_HOME", "WAYLAND_SOCKET"]
  .filter((key) => key in process.env);
if (bad.length) {
  console.error("inherited environment: " + bad.join(", "));
  process.exit(1);
}
console.log("isolated: secure");
`,
      { mode: 0o755 },
    );
    const result = spawnSync(process.execPath, [runner], {
      env: {
        PATH: bin,
        TMPDIR: dir,
        FIXTURE_DIR: dir,
        QT_PLUGIN_PATH: "/inherited-qt-plugins",
        XDG_CONFIG_HOME: "/inherited-config",
        WAYLAND_SOCKET: "3",
      },
      encoding: "utf8",
      timeout: 8000,
    });
    assert.equal(result.status, 0, result.stderr);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
