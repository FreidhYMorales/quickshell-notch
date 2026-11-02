import QtQuick
import QtTest
import Quickshell
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var recorder: Services.Recorder; property var notifs: Services.Notifs }', root)
    TestCase {
        name: "RecordingPublicationCollision"; when: true
        function test_collision() {
            root.services.recorder.start();
            tryVerify(() => root.services.recorder.recording, 3000);
            wait(500);
            root.services.recorder.stop();
            tryVerify(() => root.services.notifs.history.length > 0, 8000);
            const notification = root.services.notifs.history[0];
            if (!notification || notification.summary !== "Recording saved" || notification.body !== root.services.recorder.outputPath || root.services.recorder.preparing) {
                console.error("publication collision: saved notice missing"); return Qt.exit(1);
            }
            console.log("publication collision: saved reported"); Qt.exit(0);
        }
    }
}
