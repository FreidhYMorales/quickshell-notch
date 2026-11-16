import QtQuick
import QtTest
import Quickshell

// Drives shell/services/Session.qml directly: the idle stage is part of the
// session contract, so it can be pinned without starting the notch.
ShellRoot {
    id: root

    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var session: Services.Session }', root)
    property int requests: 0

    Connections {
        target: root.services.session

        function onLockRequested() {
            root.requests++;
        }
    }

    TestCase {
        name: "LockStage"
        when: true

        function test_stages() {
            const session = root.services.session;
            if (session.stage !== "normal")
                return Qt.exit(2);

            // The screensaver keeps the session unlocked and asks for the lock.
            session.requestIdleLock();
            if (session.stage !== "screensaver")
                return Qt.exit(3);
            if (root.requests !== 1)
                return Qt.exit(4);
            if (session.locked)
                return Qt.exit(5);

            // screensaver minutes at zero: the black stage locks the usual way.
            session.beginBlack();
            if (session.stage !== "normal")
                return Qt.exit(6);
            if (root.requests !== 2)
                return Qt.exit(7);

            // With the session locked, the black stage only darkens it: the
            // third request came from the screensaver before locking.
            session.requestIdleLock();
            session.setLocked(true);
            session.beginBlack();
            if (session.stage !== "black")
                return Qt.exit(8);
            if (root.requests !== 3)
                return Qt.exit(9);

            // A normal request still starts from today's look.
            session.requestLock();
            if (session.stage !== "normal")
                return Qt.exit(10);
            if (root.requests !== 4)
                return Qt.exit(11);

            console.log("lock stage: screensaver, normal, black, normal");
            Qt.exit(0);
        }
    }
}
