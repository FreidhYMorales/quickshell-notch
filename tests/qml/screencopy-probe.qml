import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root
    property double startedAt: 0
    property bool recorded: false

    PanelWindow {
        id: probeWindow
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
                if (hasContent && !root.recorded) {
                    root.recorded = true;
                    console.log("screencopy probe: ready " + (Date.now() - root.startedAt) + "ms " + sourceSize.width + "x" + sourceSize.height);
                    retention.start();
                }
            }
        }

        Component.onCompleted: {
            root.startedAt = Date.now();
            capture.captureSource = probeWindow.screen;
        }
    }

    Timer {
        id: retention
        interval: 500
        onTriggered: {
            if (!capture.hasContent)
                return Qt.exit(2);
            console.log("screencopy probe: retained");
            Qt.exit(0);
        }
    }
    Timer {
        interval: 5000
        running: true
        onTriggered: {
            console.warn("screencopy probe: capture timed out");
            Qt.exit(3);
        }
    }
}
