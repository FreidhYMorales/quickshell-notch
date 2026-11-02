import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var recorder: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var service: Services.Recorder }', root).service
    property var results: []
    TestCase {
        name: "RecordingSidecarClaim"; when: true
        function test_claim() {
            if (typeof root.recorder.claimSidecar === "function") {
                root.recorder.sidecarClaimed.connect(result => root.results.push(result));
                root.recorder.claimSidecar(Quickshell.env("CLAIM_SOURCE"), Quickshell.env("CLAIM_OCCUPIED"));
                tryVerify(() => root.results.length === 1, 2000);
                root.recorder.claimSidecar(Quickshell.env("CLAIM_SOURCE"), Quickshell.env("CLAIM_FREE"));
                tryVerify(() => root.results.length === 2, 2000);
            }
            if (root.results.length !== 2 || root.results[0] !== false || root.results[1] !== true) {
                console.error("sidecar claim: expected refusal then reservation"); return Qt.exit(1);
            }
            console.log("sidecar claim: refused then reserved"); Qt.exit(0);
        }
    }
}
