import QtQuick
import Quickshell

// Coordinates readiness only. The caller owns the capture views and lock.
// The caller also supplies the timeout, so this stays free of config imports
// and can be exercised from tests/qml.
Scope {
    id: root

    property int timeout: 0
    property bool pending: false
    property int generation: 0
    property var remaining: []
    signal finished(string reason)

    function finish(reason: string) {
        if (!pending)
            return;
        pending = false;
        deadline.stop();
        finished(reason);
    }

    function start(screens: var) {
        if (pending)
            return;
        generation++;
        remaining = screens.slice();
        pending = true;
        if (remaining.length === 0) {
            finish("failed");
            return;
        }
        deadline.restart();
    }

    function ready(screen: string, attempt: int) {
        if (!pending || attempt !== generation)
            return;
        const index = remaining.indexOf(screen);
        if (index < 0)
            return;
        const next = remaining.slice();
        next.splice(index, 1);
        remaining = next;
        if (remaining.length === 0)
            finish("ready");
    }

    function failed(screen: string, attempt: int) {
        if (pending && attempt === generation && remaining.indexOf(screen) >= 0)
            finish("failed");
    }

    Timer {
        id: deadline
        interval: Math.max(1, root.timeout)
        onTriggered: root.finish("timeout")
    }
}
