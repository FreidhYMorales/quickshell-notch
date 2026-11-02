import { test } from "node:test";
import assert from "node:assert/strict";
import { runTrayProbe } from "./run-tray.mjs";

test("ambiguous missing pixmap keeps Quickshell's placeholder", () => {
  const result = runTrayProbe("./tray-placeholder.qml", {
    QT_LOGGING_RULES: "quickshell.service.sni.item.warning=true",
  });
  const output = result.stdout + result.stderr;
  assert.equal(result.status, 0, output);
  assert.match(output, /Unable to create pixmap for tray icon/);
  assert.match(output, /tray icon: simulated icon is shown/);
});
