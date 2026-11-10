import QtQuick
import Quickshell

// A frame can be captured, released, and captured again for a later lock.
ShellRoot {
    id: root
    property var frame
    property int readyCount: 0
    property int cycle: 0

    PanelWindow {
        id: win
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        Item {
            id: destination
            anchors.fill: parent
        }

        Component.onCompleted: {
            root.frame = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockFrame {}', win.contentItem);
            root.frame.anchors.fill = win.contentItem;
            root.frame.frameReady.connect(function (attempt) {
                root.readyCount++;
                if (root.cycle === 0) {
                    if (attempt !== 1 || root.readyCount !== 1 || !root.frame.hasContent)
                        return Qt.exit(2);
                    if (!root.frame.attach(destination) || root.frame.visualParent !== destination)
                        return Qt.exit(3);
                    root.frame.release();
                    if (root.frame.hasContent || root.frame.visualParent !== root.frame)
                        return Qt.exit(4);
                    root.cycle = 1;
                    root.frame.start(win.screen, 2);
                    return;
                }
                if (attempt !== 2 || root.readyCount !== 2 || !root.frame.hasContent)
                    return Qt.exit(5);
                root.frame.release();
                if (root.frame.hasContent)
                    return Qt.exit(6);
                console.log("frame view: captured, released and recaptured");
                Qt.exit(0);
            });
            root.frame.start(win.screen, 1);
        }
    }

    Timer {
        interval: 8000
        running: true
        onTriggered: Qt.exit(7)
    }
}
