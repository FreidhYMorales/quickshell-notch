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
        name: "UnexpectedRecordingExit"; when: root.panel !== null && root.idle !== null
        function test_exit() {
            wait(500);
            const button = Visual.findText(root.panel.content, "󰻃");
            if (!button) { console.error("unexpected exit: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(400);
            if (!root.red(root.idle.children)) { console.error("unexpected exit: recording not active"); return Qt.exit(2); }
            wait(1100);
            if (root.red(root.idle.children)) { console.error("unexpected exit: red dot remains"); return Qt.exit(1); }
            if (!Visual.findText(root.panel.content, "Notch: Recording failed")) { console.error("unexpected exit: notification missing"); return Qt.exit(1); }
            console.log("unexpected exit: notified and dot hidden"); Qt.exit(0);
        }
    }
}
