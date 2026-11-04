import QtQuick
import Quickshell

ShellRoot {
    id: root

    property var auth: Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockPam { configDirectory: "' + Quickshell.env("NOTCH_LOCK_PAM_DIR") + '"; passwordConfig: "password"; fingerprintConfig: "fingerprint"; fingerprintEnabled: false }', root)

    Connections {
        target: root.auth
        function onUnlocked() {
            console.log("lock: unlocked");
            Qt.exit(0);
        }
        function onErrorChanged() {
            if (root.auth.error === "")
                return;
            console.log("lock: error " + root.auth.error);
            retry.start();
        }
    }

    // The next attempt starts once the failed conversation has ended.
    Timer {
        id: retry
        interval: 300
        onTriggered: root.auth.submit(Quickshell.env("NOTCH_LOCK_TRY"))
    }

    Component.onCompleted: root.auth.submit(Quickshell.env("NOTCH_LOCK_WRONG"))

    Timer {
        interval: 8000
        running: true
        onTriggered: Qt.exit(1)
    }
}
