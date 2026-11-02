import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("missing recorder reports a failure", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-missing-");
  try {
    for (
      const name of [
        "dbus-run-session",
        "dbus-daemon",
        "sh",
        "python3",
        "qs",
        "mkdir",
        "mktemp",
      ]
    ) {
      symlinkSync(`/usr/bin/${name}`, join(dir, name));
    }
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
        name: "MissingRecorder"; when: root.panel !== null
        function test_missing() {
            wait(500);
            const button = root.find(root.panel.content, "󰻃");
            if (!button) { console.error("missing recorder: no control"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(500);
            if (!root.find(root.panel.content, "Notch: Recording failed")) { console.error("missing recorder: notification absent"); return Qt.exit(1); }
            console.log("missing recorder: notification visible"); Qt.exit(0);
        }
    }
}`,
    );
    const result = runTrayProbe(join(dir, "probe.qml"), {
      PATH: dir,
      QS_RECORDINGS_DIR: dir,
      NOTCH_TEST_SURFACE: new URL(
        "../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /missing recorder: notification visible/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
