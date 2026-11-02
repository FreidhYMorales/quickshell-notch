import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var panel: null
    Timer {
        interval: 500; running: true
        onTriggered: panel = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE")).createObject(null, {screen: Quickshell.screens[0], open: true})
    }
    TestCase {
        name: "RecordingStopIcon"; when: root.panel !== null
        function test_icon() {
            wait(500);
            const button = Visual.findText(root.panel.content, "󰻃");
            if (!button) { console.error("recording icon: idle icon missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(5600);
            if (!Visual.findText(root.panel.content, "\uf04d")) {
                console.error("recording icon: stop icon missing"); return Qt.exit(1);
            }
            console.log("recording icon: stop visible"); Qt.exit(0);
        }
    }
}
