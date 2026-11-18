import QtQuick
import Quickshell

// Criterion 2: only a correct password returns to the session, and not before
// an input has ended the screensaver. The correct password is refused while the
// stage is up and accepted once the stage returns to normal.
ShellRoot {
    id: root

    property bool unlocked: false
    property var auth: Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockPam { configDirectory: "' + Quickshell.env("NOTCH_LOCK_PAM_DIR") + '"; passwordConfig: "password"; fingerprintConfig: "fingerprint"; fingerprintEnabled: false }', root)

    Connections {
        target: root.auth
        function onUnlocked() {
            root.unlocked = true;
        }
    }

    Component.onCompleted: start.start()

    Timer {
        id: start
        interval: 100
        onTriggered: {
            root.auth.listen();
            root.auth.stage = "screensaver";
            root.auth.submit(Quickshell.env("NOTCH_LOCK_TRY"));
            check.start();
        }
    }

    Timer {
        id: check
        interval: 1200
        onTriggered: {
            if (root.unlocked) {
                console.error("lock idle auth: the password unlocked during the screensaver");
                return Qt.exit(2);
            }
            console.log("lock idle auth: password blocked");
            root.auth.stage = "normal";
            root.auth.submit(Quickshell.env("NOTCH_LOCK_TRY"));
            finish.start();
        }
    }

    Timer {
        id: finish
        interval: 3000
        onTriggered: {
            if (!root.unlocked) {
                console.error("lock idle auth: the password did not unlock after the wake");
                return Qt.exit(3);
            }
            console.log("lock idle auth: password resumed");
            Qt.exit(0);
        }
    }
}
