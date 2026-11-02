import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "RecordingLeftovers"; when: true
        function test_leftovers() {
            // The idle notch reads this at startup, which creates the singleton.
            if (root.services.recorder.recording)
                console.warn("leftovers: unexpected recording");
            if (Quickshell.env("LEFTOVER_START") === "1")
                root.services.recorder.start();
            wait(2500);
            const bodies = root.services.notifs.history.map(n => n.summary + " | " + n.body);
            console.log("leftovers: " + JSON.stringify(bodies));
            Qt.exit(0);
        }
    }
}
