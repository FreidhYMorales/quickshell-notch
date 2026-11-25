import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root; property var target: null
    Timer {
        interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true });
        }
    }
    TestCase {
        name: "ControlCenterResource"
        when: root.target !== null
        function test_resource_entry_opens_visible_view() {
            const entry = Visual.findNamed(root.target.content, "cc-resource-entry");
            if (!entry) { console.error("resource view: entry is missing"); return Qt.exit(1); }
            mouseClick(entry);
            tryVerify(() => Visual.findText(root.target.content, "Resources") !== null, 1000);
            if (!Visual.findText(root.target.content, "Resources")) { console.error("resource view: visible page title is missing"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
