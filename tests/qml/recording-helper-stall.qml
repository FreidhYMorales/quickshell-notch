import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "RecordingHelperStall"; when: true
        function test_stall() {
            root.services.recorder.start();
            tryVerify(() => root.services.notifs.history.length > 0, 8000);
            if (root.services.recorder.recording || root.services.recorder.preparing) {
                console.error("helper stall: still preparing or recording"); return Qt.exit(1);
            }
            console.log("helper stall: reported"); Qt.exit(0);
        }
    }
}
