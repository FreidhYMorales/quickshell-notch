import QtQuick
import Quickshell

ShellRoot {
    id: root

    property bool unlocked: false
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var session: Services.Session }', root)
    property var auth: Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockPam { configDirectory: "' + Quickshell.env("NOTCH_LOCK_PAM_DIR") + '"; fingerprintConfig: "fingerprint"; fingerprintEnabled: true }', root)

    Connections {
        target: root.services.session
        function onStageChanged() {
            if ("stage" in root.auth)
                root.auth.stage = root.services.session.stage;
        }
    }

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
            root.services.session.requestIdleLock();
            check.start();
        }
    }

    Timer {
        id: check
        interval: 1200
        onTriggered: {
            if (root.unlocked) {
                console.error("lock stage: fingerprint unlocked during screensaver");
                return Qt.exit(2);
            }
            console.log("lock stage: fingerprint blocked");
            root.services.session.endStage();
            finish.start();
        }
    }

    Timer {
        id: finish
        interval: 2000
        onTriggered: {
            if (!root.unlocked) {
                console.error("lock stage: fingerprint did not unlock after wake");
                return Qt.exit(3);
            }
            console.log("lock stage: fingerprint resumed");
            Qt.exit(0);
        }
    }
}
