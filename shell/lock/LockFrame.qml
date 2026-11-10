import QtQuick
import Quickshell.Wayland

// One instance per screen. Captures a still frame on demand and can be reused
// for a later lock; it never locks a session itself.
Item {
    id: root

    property var screen: null
    property int attempt: 0
    property bool active: false
    property bool captured: false
    property bool failed: false
    readonly property bool hasContent: capture ? capture.hasContent : false
    readonly property var visualParent: capture ? capture.parent : null
    signal frameReady(int attempt)
    signal frameFailed(int attempt)

    function start(screen: var, attempt: int): void {
        root.attempt = attempt;
        root.screen = screen;
        root.captured = false;
        root.failed = false;
        root.active = true;
    }

    function attach(target: var): bool {
        if (!target || !capture || !capture.hasContent)
            return false;
        capture.anchors.fill = null;
        capture.parent = target;
        capture.anchors.fill = target;
        return true;
    }

    function release(): void {
        root.active = false;
        if (!capture)
            return;
        capture.anchors.fill = null;
        capture.parent = root;
        capture.anchors.fill = root;
    }

    ScreencopyView {
        id: capture
        anchors.fill: parent
        live: false
        captureSource: root.active ? root.screen : null
        onHasContentChanged: {
            if (hasContent && root.active && !root.captured) {
                root.captured = true;
                root.frameReady(root.attempt);
            }
        }
        onStopped: {
            if (root.active && !root.captured && !root.failed) {
                root.failed = true;
                root.frameFailed(root.attempt);
            }
        }
    }
}
