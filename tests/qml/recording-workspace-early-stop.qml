import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "RecordingWorkspaceEarlyStop"; when: true
        function test_stop() {
            root.services.recorder.start();
            if (!root.services.recorder.preparing) { console.error("preparation stop: invalid setup"); return Qt.exit(2); }
            root.services.recorder.stop();
            tryVerify(() => root.services.notifs.history.length > 0, 6000);
            if (!root.services.notifs.history.length || root.services.notifs.history[0].summary !== "Recording saved") {
                console.error("preparation stop: saved notice missing"); return Qt.exit(1);
            }
            console.log("preparation stop: saved"); Qt.exit(0);
        }
    }
}
