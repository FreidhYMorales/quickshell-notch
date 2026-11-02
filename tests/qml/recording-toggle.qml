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
        name: "RecordingToggle"; when: root.panel !== null && root.idle !== null
        function test_toggle() {
            wait(500);
            const glyph = Visual.findText(root.panel.content, "󰻃");
            if (glyph === null || root.red(root.idle.children)) {
                console.error("recording start: invalid initial display");
                return Qt.exit(2);
            }
            mouseClick(glyph, glyph.width / 2, glyph.height / 2);
            wait(500);
            if (!root.red(root.idle.children)) {
                console.error("recording start: red dot missing");
                return Qt.exit(1);
            }
            console.log("recording start: red dot visible"); Qt.exit(0);
        }
    }
}
