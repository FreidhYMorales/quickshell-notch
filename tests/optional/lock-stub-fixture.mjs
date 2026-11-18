import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

export function createLockStub(clientSource) {
  const dir = mkdtempSync(join(tmpdir(), "notch-lock-stub-"));
  const script = (name, content) =>
    writeFileSync(join(dir, name), content, { mode: 0o755 });
  script("pkg-config", "#!/bin/sh\nexit 0\n");
  script(
    "cc",
    `#!/bin/sh
while [ "$1" != "-o" ]; do shift; done
shift
/bin/cp "$FIXTURE_DIR/server-fixture" "$1"
/bin/chmod +x "$1"
`,
  );
  script(
    "server-fixture",
    `#!${process.execPath}
require("node:net").createServer().listen(
  require("node:path").join(process.env.XDG_RUNTIME_DIR, "notch-test"),
  () => console.log("isolated: ready"),
);
`,
  );
  script("qs", `#!${process.execPath}\n${clientSource}\n`);
  const runner = fileURLToPath(
    new URL("./lock-isolation.mjs", import.meta.url),
  );
  return {
    dir,
    run: () =>
      spawnSync(process.execPath, [runner], {
        env: { PATH: dir, TMPDIR: dir, FIXTURE_DIR: dir },
        encoding: "utf8",
        timeout: 8000,
      }),
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}
