import { test } from "node:test";
import assert from "node:assert/strict";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

test("other test entry points disable Quickshell crash relaunch", () => {
  const dir = mkdtempSync("/tmp/opencode/other-runners-");
  try {
    const fakeQs = join(dir, "qs");
    writeFileSync(
      fakeQs,
      `#!/usr/bin/node
if (process.env.QS_DISABLE_CRASH_HANDLER !== "1") process.exit(42);
if (process.argv.join(" ").includes("exit-probe.qml")) {
  if (process.env.NOTCH_QML_TEST_FAIL === "1") {
    console.log("notch-qml-test: expected failure"); process.exit(7);
  }
  console.log("notch-qml-test: success");
}
console.log("notch-tray-test: simulated item detected");
console.log("empty tray: corner stays hidden and click-through");
`,
    );
    chmodSync(fakeQs, 0o755);
    const env = Object.assign({}, process.env, {
      PATH: dir + ":" + process.env.PATH,
      QS_DISABLE_CRASH_HANDLER: "",
    });
    delete env.NODE_TEST_CONTEXT;
    for (
      const [command, args] of [
        ["node", ["--test", "tests/qml/qs-runtime.mjs"]],
        ["node", ["--test", "tests/qml/tray-empty.mjs"]],
        ["make", ["smoke"]],
      ]
    ) {
      const result = spawnSync(command, args, {
        encoding: "utf8",
        env,
        timeout: 20000,
      });
      assert.equal(result.status, 0, result.stdout + result.stderr);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
