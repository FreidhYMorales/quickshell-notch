import QtQuick
import Quickshell

ShellRoot {
    id: root

    property var auth: Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockPam { configDirectory: "' + Quickshell.env("NOTCH_LOCK_PAM_DIR") + '"; passwordConfig: "password"; fingerprintConfig: "fingerprint"; fingerprintEnabled: true }', root)

    Connections {
        target: root.auth
        function onUnlocked() {
            console.log("lock: unlocked");
            Qt.exit(0);
        }
    }

    Component.onCompleted: root.auth.listen()

    Timer {
        interval: 8000
        running: true
        onTriggered: Qt.exit(1)
    }
}
