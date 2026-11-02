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
        name: "RecordingSavedNotification"; when: root.panel !== null && root.idle !== null
        function test_saved() {
            wait(500);
            const button = Visual.findText(root.panel.content, "󰻃");
            if (!button) { console.error("recording saved: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2);
            tryVerify(() => root.red(root.idle.children), 6500);
            if (!root.red(root.idle.children)) { console.error("recording saved: capture missing"); return Qt.exit(2); }
            if (Visual.findText(root.panel.content, "Notch: Recording saved")) { console.error("recording saved: premature notification"); return Qt.exit(1); }
            mouseClick(button, button.width / 2, button.height / 2); wait(500);
            if (!Visual.findText(root.panel.content, "Notch: Recording saved")) { console.error("recording saved: notification missing"); return Qt.exit(1); }
            console.log("recording saved: notification visible"); Qt.exit(0);
        }
    }
}
