import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root

    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var session: Services.Session; property var sleep: Services.SleepLock }', root)
    property bool requested: false

    Connections {
        target: root.services.session
        function onLockRequested() {
            console.log("sleep lock: lock requested");
            root.requested = true;
        }
    }

    TestCase {
        name: "SleepLock"
        when: true

        function test_sleep() {
            root.services.sleep.toString();
            tryVerify(() => root.requested, 5000);
            wait(500);
            // The compositor confirms the lock: the inhibitor must go.
            root.services.session.setSecure(true);
            wait(800);
            // Resume: the inhibitor must come back.
            const resume = Qt.createQmlObject('import Quickshell.Io; Process { command: ["touch", "' + Quickshell.env("NOTCH_SLEEP_DIR") + '/resume"] }', root);
            resume.running = true;
            wait(1200);
            Qt.exit(0);
        }
    }
}
