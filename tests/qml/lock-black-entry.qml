import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var lock: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var session: Services.Session }', root)

    Component.onCompleted: setup.start()

    Timer {
        id: setup
        interval: 100
        onTriggered: {
            root.lock = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; Lock {}', root);
            root.services.session.setLocked(true);
            root.services.session.beginBlack();
            inspect.start();
        }
    }

    Timer {
        id: inspect
        interval: 180
        onTriggered: {
            if (root.lock.overlay <= 0 || root.lock.overlay >= 1 || !root.lock.outputsOn) {
                console.error("lock black: expected expansion while outputs remain on; overlay=" + root.lock.overlay + ", on=" + root.lock.outputsOn);
                return Qt.exit(2);
            }
            complete.start();
        }
    }

    Timer {
        id: complete
        interval: 800
        onTriggered: {
            if (root.lock.overlay !== 1 || root.lock.outputsOn) {
                console.error("lock black: expected fullscreen frame and outputs off");
                return Qt.exit(3);
            }
            console.log("lock black: expanded before outputs off");
            Qt.exit(0);
        }
    }
}
