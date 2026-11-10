import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var gate
    property int calls: 0
    property string outcome: ""
    property int step: 0

    function completed(reason) {
        calls++;
        outcome = reason;
    }

    Component.onCompleted: {
        gate = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; LockFrameGate { timeout: 80 }', root);
        gate.finished.connect(root.completed);
        // Every screen must be ready, and duplicate/unknown signals do nothing.
        gate.start(["A", "B"]);
        const first = gate.generation;
        gate.ready("A", first);
        gate.ready("A", first);
        gate.ready("unknown", first);
        if (calls !== 0)
            return Qt.exit(2);
        gate.ready("B", first);
        gate.ready("B", first);
        if (calls !== 1 || outcome !== "ready")
            return Qt.exit(3);
        gate.start(["A"]);
        const second = gate.generation;
        gate.ready("A", first);
        if (calls !== 1)
            return Qt.exit(7);
        gate.failed("A", second);
        gate.ready("A", second);
        if (calls !== 2 || outcome !== "failed")
            return Qt.exit(4);
        gate.start(["A"]);
        timeoutCheck.start();
    }

    Timer {
        id: timeoutCheck
        interval: 200
        onTriggered: {
            if (root.calls !== 3 || root.outcome !== "timeout")
                return Qt.exit(5);
            root.gate.ready("A", root.gate.generation);
            if (root.calls !== 3)
                return Qt.exit(6);
            console.log("frame gate: all scenarios passed");
            Qt.exit(0);
        }
    }
}
