import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var idle: null
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    Timer {
        interval: 500; running: true
        onTriggered: idle = Qt.createComponent(Quickshell.env("NOTCH_TEST_IDLE")).createObject(null, {screen: Quickshell.screens[0]})
    }
    TestCase {
        name: "RecordingCountdownDisplay"; when: root.idle !== null
        function test_display() {
            if (typeof root.recorder.setRecording !== "function") { console.error("countdown display: invalid setup"); return Qt.exit(2); }
            if ("countdown" in root.recorder) root.recorder.countdown = 5;
            wait(100);
            if (!Visual.findText(root.idle.children, "5")) { console.error("countdown display: 5 missing"); return Qt.exit(1); }
            root.recorder.countdown = 1; wait(100);
            if (Visual.findText(root.idle.children, "5") || !Visual.findText(root.idle.children, "1")) { console.error("countdown display: 1 missing"); return Qt.exit(1); }
            root.recorder.countdown = 0; wait(100);
            if (Visual.findText(root.idle.children, "1")) { console.error("countdown display: still visible"); return Qt.exit(1); }
            console.log("countdown display: 5, 1, hidden"); Qt.exit(0);
        }
    }
}
