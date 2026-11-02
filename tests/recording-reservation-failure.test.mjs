import { test } from "node:test";
import assert from "node:assert/strict";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("failure to reserve an output file is reported", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-reserve-failure-");
  try {
    writeFileSync(
      join(dir, "mktemp"),
      '#!/bin/sh\nprintf failed > "$RESERVE_LOG"\nexit 1\n',
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "gpu-screen-recorder"),
      '#!/bin/sh\nprintf started > "$CAPTURE_LOG"\n',
      { mode: 0o755 },
    );
    writeFileSync(
      join(dir, "probe.qml"),
      `
import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var panel: null
    function find(items, value) {
        for (const item of items) {
            if (item.visible && item.text === value) return item;
            const found = item.children && item.children.length && find(item.children, value);
            if (found) return found;
        }
        return null;
    }
    Timer { running: true; interval: 500; onTriggered: root.panel = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE")).createObject(null, {screen: Quickshell.screens[0], open: true}) }
    TestCase {
        name: "RecordingReservationFailure"; when: root.panel !== null
        function test_failure() {
            wait(500);
            const button = root.find(root.panel.content, "󰻃");
            if (!button) { console.error("reservation failure: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(5600);
            if (!root.find(root.panel.content, "Notch: Recording failed")) { console.error("reservation failure: notification missing"); return Qt.exit(1); }
            console.log("reservation failure: notification visible"); Qt.exit(0);
        }
    }
}`,
    );
    const reserveLog = join(dir, "reserve.log");
    const captureLog = join(dir, "capture.log");
    const result = runTrayProbe(join(dir, "probe.qml"), {
      PATH: `${dir}:${process.env.PATH}`,
      RESERVE_LOG: reserveLog,
      CAPTURE_LOG: captureLog,
      QS_RECORDINGS_DIR: join(dir, "recordings"),
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
    });
    assert.equal(readFileSync(reserveLog, "utf8"), "failed");
    assert.equal(existsSync(captureLog), false, "capture must not start");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /reservation failure: notification visible/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
