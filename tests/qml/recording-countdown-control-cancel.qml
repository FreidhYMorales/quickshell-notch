import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var panel: null
    property var idle: null
    function red(items) {
        for (const item of items) {
            if (item.visible && item.color !== undefined && String(item.color) === "#ff3b30") return true;
            if (item.children && item.children.length && red(item.children)) return true;
        }
        return false;
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            panel = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE")).createObject(null, {screen: Quickshell.screens[0], open: true});
            idle = Qt.createComponent(Quickshell.env("NOTCH_TEST_IDLE")).createObject(null, {screen: Quickshell.screens[0]});
        }
    }
    TestCase {
        name: "RecordingCountdownControlCancel"; when: root.panel !== null && root.idle !== null
        function test_cancel() {
            wait(500);
            const button = Visual.findText(root.panel.content, "󰻃");
            if (!button) { console.error("countdown UI cancel: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(100);
            if (!Visual.findText(root.idle.children, "5")) { console.error("countdown UI cancel: countdown missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(100);
            if (Visual.findText(root.idle.children, "5")) { console.error("countdown UI cancel: countdown still visible"); return Qt.exit(1); }
            wait(5300);
            if (root.red(root.idle.children)) { console.error("countdown UI cancel: recording started"); return Qt.exit(1); }
            console.log("countdown UI cancel: no capture"); Qt.exit(0);
        }
    }
}
