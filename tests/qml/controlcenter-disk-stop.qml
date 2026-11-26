import QtQuick
import QtTest
import Quickshell
import Quickshell.Io

ShellRoot { id: root; property var target: null
    FileView { id: replacement; path: Quickshell.env("NOTCH_SYSINFO_DISKSTATS") }
    Timer { interval: 400; running: true; onTriggered: { const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml"); if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2); root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true }); }}
    TestCase { name: "ControlCenterDiskStop"; when: root.target !== null
        function test_polling_stops_after_last_close() { wait(2800); if (!root.target.resourceStats.diskActivity) { console.error("disk polling: open panel has no rate sample"); return Qt.exit(1); } root.target.open = false; replacement.setText("invalid diskstats\n"); replacement.waitForJob(); wait(2300); if (!root.target.resourceStats.diskActivity) { console.error("disk polling: closed panel continued sampling"); return Qt.exit(1); } Qt.exit(0); }
    }
}
