import QtQuick
import Quickshell

// Whether the lock listens for a finger follows the security view's switch
// live, without a restart. Runs under smoke, so no session lock is requested.
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
            const on = root.lock.fingerprintEnabled;
            security.setFingerprintEnabled(false);
            const off = root.lock.fingerprintEnabled;
            console.log("lock security switch: on " + on + ", off " + off);
            Qt.exit(0);
        }
    }
}
