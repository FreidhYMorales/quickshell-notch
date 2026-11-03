import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync } from "node:fs";

test("polkit runtime probes run in the QML suite, not unit CI", () => {
  const unitFiles = readdirSync(new URL(".", import.meta.url));
  const qmlFiles = readdirSync(new URL("./qml", import.meta.url));
  assert.deepEqual(
    unitFiles.filter((name) =>
      ["polkitRegistration.test.mjs", "polkitFlowNoMonitor.test.mjs"].includes(
        name,
      )
    ),
    [],
  );
  assert.ok(qmlFiles.includes("polkit-agent-registration.mjs"));
  assert.ok(qmlFiles.includes("polkit-flow-no-monitor.mjs"));
});
