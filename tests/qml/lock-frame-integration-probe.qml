import QtQuick
import Quickshell
import Quickshell.Wayland

// Manual experiment only; it automatically releases its own test lock and
// must never be used as an authentication lock. The lock components are
// created from a file URL because a relative directory import from tests/qml
// cannot resolve their own imports.
ShellRoot {
    id: root
    property var target: null
    property var gate: null
    property var frame: null
    property string result: ""
    property bool finished: false
    property double startedAt: 0
    readonly property string lockUrl: Quickshell.env("NOTCH_LOCK_URL") || ""

    PanelWindow {
        id: sourceWindow
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        Component.onCompleted: {
            root.startedAt = Date.now();
            if (!sourceWindow.screen) {
                console.warn("integration probe: no screen");
                Qt.callLater(() => Qt.exit(2));
                return;
            }
            if (root.lockUrl === "") {
                console.warn("integration probe: NOTCH_LOCK_URL is not set");
                Qt.callLater(() => Qt.exit(3));
                return;
            }
            root.gate = Qt.createQmlObject('import "' + root.lockUrl + '"; LockFrameGate { timeout: 500 }', root);
            root.gate.finished.connect(reason => {
                root.result = reason;
                console.log("integration probe: " + reason + " at " + (Date.now() - root.startedAt) + "ms; requesting lock");
                lock.locked = true;
            });
            root.frame = Qt.createQmlObject('import "' + root.lockUrl + '"; LockFrame {}', sourceWindow.contentItem);
            root.frame.anchors.fill = sourceWindow.contentItem;
            root.frame.frameReady.connect(attempt => root.gate.ready(sourceWindow.screen.name, attempt));
            root.frame.frameFailed.connect(attempt => root.gate.failed(sourceWindow.screen.name, attempt));
            root.gate.start([sourceWindow.screen.name]);
            root.frame.start(sourceWindow.screen, root.gate.generation);
        }
    }

    WlSessionLock {
        id: lock
        onSecureChanged: {
            if (!secure || root.finished)
                return;
            if (root.target && root.result === "ready") {
                root.frame.attach(root.target);
                console.log("integration probe: attached=" + (root.frame.visualParent === root.target));
            } else
                console.warn("integration probe: no frame to show; target=" + (root.target !== null) + "; reason=" + root.result);
            console.log("integration probe: secure at " + (Date.now() - root.startedAt) + "ms; frame=" + (root.frame !== null && root.frame.hasContent) + "; reason=" + root.result);
            releaseTimer.start();
        }
        WlSessionLockSurface {
            color: "black"
            Item {
                id: imageTarget
                anchors.fill: parent
                Component.onCompleted: root.target = imageTarget
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
        interval: 3000
        onTriggered: {
            root.finished = true;
            console.log("integration probe: unlocking without releasing the frame");
            lock.locked = false;
            inspectTimer.start();
        }
    }
    Timer {
        id: inspectTimer
        interval: 700
        onTriggered: {
            try {
                console.log("integration probe: after unlock; retained=" + root.frame.hasContent + "; home=" + (root.frame.visualParent === root.frame));
                if (root.frame)
                    root.frame.release();
                console.log("integration probe: released after unlock");
            } catch (e) {
                console.warn("integration probe: frame unusable after unlock: " + e);
            }
            Qt.exit(0);
        }
    }
    Timer {
        interval: 10000
        running: true
        onTriggered: {
            if (!root.finished) {
                root.finished = true;
                console.warn("integration probe: timeout; releasing test lock");
                if (root.frame)
                    root.frame.release();
                lock.locked = false;
                Qt.exit(0);
            }
        }
    }
}
