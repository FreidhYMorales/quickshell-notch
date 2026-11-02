import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var idle: null
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    function red(items) {
        for (const item of items) {
            if (item.visible && item.color !== undefined && String(item.color) === "#ff3b30") return true;
            if (item.children && item.children.length && red(item.children)) return true;
        }
        return false;
    }
    Timer {
        interval: 500; running: true
        onTriggered: idle = Qt.createComponent(Quickshell.env("NOTCH_TEST_IDLE")).createObject(null, {screen: Quickshell.screens[0]})
    }
    TestCase {
        name: "RecordingCountdownTimer"; when: root.idle !== null
        function test_timer() {
            if (typeof root.recorder.setRecording !== "function") { console.error("countdown timer: invalid setup"); return Qt.exit(2); }
            const began = Date.now();
            if (typeof root.recorder.beginCountdown === "function") root.recorder.beginCountdown();
            wait(100);
            if (!Visual.findText(root.idle.children, "5") || root.red(root.idle.children)) { console.error("countdown timer: initial countdown missing"); return Qt.exit(1); }
            wait(1000);
            if (!Visual.findText(root.idle.children, "4") || root.red(root.idle.children)) { console.error("countdown timer: 4 missing or capture early"); return Qt.exit(1); }
            wait(3000);
            if (!Visual.findText(root.idle.children, "1") || root.red(root.idle.children)) { console.error("countdown timer: 1 missing or capture early"); return Qt.exit(1); }
            wait(1100);
            if (Date.now() - began < 5000 || !root.red(root.idle.children)) { console.error("countdown timer: capture did not start after countdown"); return Qt.exit(1); }
            console.log("countdown timer: completed before capture"); Qt.exit(0);
        }
    }
}
