import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { runTrayProbe } from "./qml/run-tray.mjs";

test("missing recorder leaves no red dot", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-missing-dot-");
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
    ) symlinkSync(`/usr/bin/${name}`, join(dir, name));
    writeFileSync(
      join(dir, "probe.qml"),
      `
import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var panel: null
    property var idle: null
    function find(items, value) {
        for (const item of items) {
            if (item.visible && item.text === value) return item;
            const found = item.children && item.children.length && find(item.children, value);
            if (found) return found;
        }
        return null;
    }
    function red(items) {
        for (const item of items) {
            if (item.visible && item.color !== undefined && String(item.color) === "#ff3b30") return true;
            if (item.children && item.children.length && red(item.children)) return true;
        }
        return false;
    }
    Timer { running: true; interval: 500; onTriggered: {
        panel = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE")).createObject(null, {screen: Quickshell.screens[0], open: true});
        idle = Qt.createComponent(Quickshell.env("NOTCH_TEST_IDLE")).createObject(null, {screen: Quickshell.screens[0]});
    } }
    TestCase {
        name: "MissingRecorderDot"; when: root.panel !== null && root.idle !== null
        function test_missing() {
            wait(500);
            const button = root.find(root.panel.content, "󰻃");
            if (!button) { console.error("missing dot: no control"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(5600);
            if (!root.find(root.panel.content, "Notch: Recording failed")) { console.error("missing dot: failure not observed"); return Qt.exit(2); }
            if (root.red(root.idle.children)) { console.error("missing dot: red dot remains"); return Qt.exit(1); }
            console.log("missing dot: red dot hidden"); Qt.exit(0);
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
      NOTCH_TEST_IDLE:
        new URL("../shell/notches/center/CenterIdle.qml", import.meta.url).href,
    });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /missing dot: red dot hidden/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
