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
        name: "RecordingCountdownCancel"; when: root.idle !== null
        function test_cancel() {
            if (typeof root.recorder.beginCountdown !== "function") { console.error("countdown cancel: timer unavailable"); return Qt.exit(2); }
            root.recorder.beginCountdown(); wait(100);
            if (!Visual.findText(root.idle.children, "5")) { console.error("countdown cancel: countdown did not start"); return Qt.exit(2); }
            if (typeof root.recorder.cancelCountdown === "function") root.recorder.cancelCountdown();
            wait(100);
            if (Visual.findText(root.idle.children, "5")) { console.error("countdown cancel: countdown still visible"); return Qt.exit(1); }
            wait(5300);
            if (root.recorder.recording) { console.error("countdown cancel: recording started"); return Qt.exit(1); }
            console.log("countdown cancel: no capture"); Qt.exit(0);
        }
    }
}
