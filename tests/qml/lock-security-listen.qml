import QtQuick
import Quickshell

// The lock's PAM listener (the part that waits for a finger) follows the
// security view's switch live. Runs under smoke: no session lock is requested.
ShellRoot {
    id: root
    property var lock: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var security: Services.Security }', root)
    Component.onCompleted: check.start()
    Timer {
        id: check
        interval: 100
        onTriggered: {
            root.lock = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; Lock {}', root);
            const security = root.services.security;
            security.setFingerprintEnabled(true);
            const on = root.lock.auth ? root.lock.auth.fingerprintEnabled : "none";
            security.setFingerprintEnabled(false);
            const off = root.lock.auth ? root.lock.auth.fingerprintEnabled : "none";
            console.log("lock listens: on " + on + ", off " + off);
            Qt.exit(0);
        }
    }
}
