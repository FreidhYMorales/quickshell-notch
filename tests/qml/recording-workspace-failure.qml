import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    property var paths: []
    TestCase {
        name: "RecordingWorkspaceFailure"; when: true
        function test_failure() {
            root.recorder.workspaceCreated.connect(path => root.paths.push(path));
            root.recorder.createWorkspace(Quickshell.env("WORKSPACE_PARENT"));
            tryVerify(() => root.paths.length === 1, 2000);
            if (root.paths[0] !== "") {
                console.error("workspace failure: accepted failed path"); return Qt.exit(1);
            }
            console.log("workspace failure: rejected"); Qt.exit(0);
        }
    }
}
