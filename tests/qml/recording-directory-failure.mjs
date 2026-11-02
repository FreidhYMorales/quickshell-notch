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
import { runTrayProbe } from "./run-tray.mjs";

test("an uncreatable recording directory reports failure", () => {
  const dir = mkdtempSync("/tmp/opencode/notch-dir-failure-");
  try {
    const blocked = join(dir, "blocked");
    writeFileSync(blocked, "keep existing file");
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
        name: "RecordingDirectoryFailure"; when: root.panel !== null
        function test_failure() {
            wait(500);
            const button = root.find(root.panel.content, "󰻃");
            if (!button) { console.error("directory failure: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(5600);
            if (!root.find(root.panel.content, "Notch: Recording failed")) { console.error("directory failure: notification missing"); return Qt.exit(1); }
            console.log("directory failure: notification visible"); Qt.exit(0);
        }
    }
}`,
    );
    const log = join(dir, "capture.log");
    const result = runTrayProbe(join(dir, "probe.qml"), {
      PATH: `${dir}:${process.env.PATH}`,
      CAPTURE_LOG: log,
      QS_RECORDINGS_DIR: join(blocked, "recordings"),
      NOTCH_TEST_SURFACE: new URL(
        "../../shell/notches/controlcenter/ControlCenterSurface.qml",
        import.meta.url,
      ).href,
    });
    assert.equal(existsSync(log), false, "capture must not start");
    assert.equal(readFileSync(blocked, "utf8"), "keep existing file");
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(
      result.stdout + result.stderr,
      /directory failure: notification visible/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
