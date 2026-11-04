// Real-flow polkit tests start the system's polkit-agent-helper-1, which runs
// PAM for the identity they request. Requesting the current user makes every
// cancelled probe a failed login, and pam_faillock then locks the developer
// out. They must authenticate as a user that cannot log in instead.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";

const dir = new URL("./qml/", import.meta.url);

test("real-flow polkit tests never authenticate as the current user", () => {
  const offenders = readdirSync(dir)
    .filter((name) => name.startsWith("polkit-") && name.endsWith(".mjs"))
    .filter((name) =>
      readFileSync(new URL(name, dir), "utf8").includes("os.getuid()")
    );
  assert.deepEqual(offenders, []);
});
