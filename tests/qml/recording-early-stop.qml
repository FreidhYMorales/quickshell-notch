import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var panel: null
    property string events: ""
    FileView {
        path: Quickshell.env("EVENT_LOG")
        watchChanges: true
        onLoaded: root.events = text()
        onFileChanged: reload()
    }
    Timer {
        interval: 500; running: true
        onTriggered: panel = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE")).createObject(null, {screen: Quickshell.screens[0], open: true})
    }
    TestCase {
        name: "RecordingEarlyStop"; when: root.panel !== null
        function test_stop() {
            wait(500);
            const button = Visual.findText(root.panel.content, "󰻃");
            if (!button) { console.error("early stop: control missing"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2);
            tryVerify(() => root.events.includes("started"), 7000);
            if (!root.events.includes("started") || root.events.includes("ready")) { console.error("early stop: invalid preparation setup"); return Qt.exit(2); }
            mouseClick(button, button.width / 2, button.height / 2); wait(2600);
            if (!Visual.findText(root.panel.content, "Notch: Recording saved")) { console.error("early stop: saved notification missing"); return Qt.exit(1); }
            console.log("early stop: saved after readiness"); Qt.exit(0);
        }
    }
}
