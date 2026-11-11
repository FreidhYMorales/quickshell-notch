import QtQuick
import Quickshell
import Quickshell.Wayland

// Manual experiment only: this intentionally releases its own test lock after
// a short interval. It must never be used as the session's real lock screen.
ShellRoot {
    id: root
    property bool captured: false
    property bool finished: false
    property var lockTarget: null
    property bool concurrent: Quickshell.env("SCREENCOPY_CONCURRENT") === "1"
    property double startedAt: 0

    function showFrame() {
        if (!captured || !lock.secure || !lockTarget)
            return;
        capture.anchors.fill = null;
        capture.parent = lockTarget;
        capture.anchors.fill = lockTarget;
        console.log("lock probe: frame attached at " + (Date.now() - startedAt) + "ms; retained=" + capture.hasContent);
    }

    PanelWindow {
        id: sourceWindow
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        ScreencopyView {
            id: capture
            anchors.fill: parent
            live: false
            onHasContentChanged: {
                if (hasContent && !root.captured) {
                    root.captured = true;
                    console.log("lock probe: frame ready at " + (Date.now() - root.startedAt) + "ms");
                    if (!root.concurrent)
                        lock.locked = true;
                    root.showFrame();
                }
            }
        }

        Component.onCompleted: {
            root.startedAt = Date.now();
            capture.captureSource = sourceWindow.screen;
            if (root.concurrent) {
                console.log("lock probe: requesting concurrent test lock");
                lock.locked = true;
            }
        }
    }

    WlSessionLock {
        id: lock
        onSecureChanged: {
            if (secure && !root.finished) {
                if (!root.lockTarget) {
                    console.warn("lock probe: lock surface is not ready");
                    return;
                }
                console.log("lock probe: secure at " + (Date.now() - root.startedAt) + "ms; retained=" + capture.hasContent);
                root.showFrame();
                releaseTimer.start();
            }
        }
        WlSessionLockSurface {
            color: "black"
            Item {
                id: lockedImage
                anchors.fill: parent
                Component.onCompleted: root.lockTarget = lockedImage
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                width: label.implicitWidth + 40
                height: label.implicitHeight + 20
                radius: 8
                color: "black"
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: "PRUEBA: se cerrará automáticamente en 4 segundos"
                    color: "white"
                    font.pixelSize: 18
                }
            }
        }
    }

    Timer {
        id: releaseTimer
        interval: 4000
        onTriggered: {
            root.finished = true;
            console.log("lock probe: releasing; retained=" + capture.hasContent);
            lock.locked = false;
            exitTimer.start();
        }
    }
    Timer {
        id: exitTimer
        interval: 500
        onTriggered: Qt.exit(0)
    }
    Timer {
        interval: 10000
        running: true
        onTriggered: {
            if (!root.finished) {
                root.finished = true;
                console.warn("lock probe: timeout; releasing test lock");
                lock.locked = false;
                exitTimer.start();
            }
        }
    }
}
