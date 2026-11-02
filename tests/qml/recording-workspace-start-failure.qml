import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "WorkspaceStartFailure"; when: true
        function test_failure() {
            root.services.recorder.start();
            tryVerify(() => root.services.notifs.history.length > 0, 3000);
            if (root.services.recorder.recording) { console.error("workspace start failure: still recording"); return Qt.exit(1); }
            console.log("workspace start failure: reported"); Qt.exit(0);
        }
    }
}
