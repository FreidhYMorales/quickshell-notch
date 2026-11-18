import QtQuick
import Quickshell

// The screensaver layer must not survive a stage that returns to normal while
// the session stays locked: that is what a manual lock request does (it sets
// the stage to normal and the lock connection ignores a request that is already
// locked, so the stage change is the whole effect). Entering the stage directly
// keeps this probe from asking for a real session lock.
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
            root.services.session.privateStage = "screensaver";
            full.start();
        }
    }

    Timer {
        id: full
        interval: 700
        onTriggered: {
            if (root.lock.overlay !== 1 || root.lock.overlayKind !== "wallpaper") {
                console.error("lock manual layer: the screensaver layer never covered the form; overlay=" + root.lock.overlay + ", kind=" + root.lock.overlayKind);
                return Qt.exit(2);
            }
            root.services.session.endStage();
            contracted.start();
        }
    }

    Timer {
        id: contracted
        interval: 700
        onTriggered: {
            if (root.lock.overlay !== 0 || root.lock.overlayKind !== "") {
                console.error("lock manual layer: the layer stayed over the form; overlay=" + root.lock.overlay + ", kind=" + root.lock.overlayKind);
                return Qt.exit(3);
            }
            console.log("lock manual layer: contracted into the notch");
            Qt.exit(0);
        }
    }
}
