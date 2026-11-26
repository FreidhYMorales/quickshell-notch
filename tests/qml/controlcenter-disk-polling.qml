import QtQuick
import QtTest
import Quickshell

ShellRoot { id: root; property var target: null
    Timer { interval: 400; running: true; onTriggered: { const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml"); if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2); root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true }); }}
    TestCase { name: "ControlCenterDiskPolling"; when: root.target !== null
        function test_open_control_center_receives_disk_activity() {
            wait(2800); const first = root.target.resourceStats.diskActivity;
            if (!first || first.readBytesPerSecond !== 0 || first.writeBytesPerSecond !== 0) { console.error("disk polling: open panel has no zero-rate sample"); return Qt.exit(1); }
            Qt.exit(0); }}
}
