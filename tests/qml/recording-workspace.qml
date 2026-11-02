import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    property var paths: []
    TestCase {
        name: "RecordingWorkspace"; when: true
        function test_workspace() {
            if (typeof root.recorder.createWorkspace !== "function") {
                console.error("workspace: create operation missing"); return Qt.exit(1);
            }
            root.recorder.workspaceCreated.connect(path => root.paths.push(path));
            root.recorder.createWorkspace(Quickshell.env("WORKSPACE_PARENT"));
            tryVerify(() => root.paths.length === 1, 2000);
            root.recorder.createWorkspace(Quickshell.env("WORKSPACE_PARENT"));
            tryVerify(() => root.paths.length === 2, 2000);
            if (!root.paths[0] || !root.paths[1] || root.paths[0] === root.paths[1]) {
                console.error("workspace: invalid paths"); return Qt.exit(1);
            }
            console.log("workspace: two unique paths"); Qt.exit(0);
        }
    }
}
