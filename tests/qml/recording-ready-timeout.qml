import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "RecordingReadyTimeout"; when: true
        function test_timeout() {
            root.services.recorder.start();
            tryVerify(() => root.services.recorder.recording, 3000);
            tryVerify(() => root.services.notifs.history.length > 0, 19000);
            if (root.services.recorder.recording || !root.services.notifs.history.length || !root.services.notifs.history[0].body.includes(root.services.recorder.capturePath)) {
                console.error("ready timeout: state or notification invalid"); return Qt.exit(1);
            }
            console.log("ready timeout: stopped and reported"); Qt.exit(0);
        }
    }
}
