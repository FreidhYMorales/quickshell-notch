import QtQuick
import QtTest
import Quickshell

ShellRoot { id: root; property var target: null
    Timer { interval: 400; running: true; onTriggered: { const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml"); if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2); root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true }); }}
    TestCase { name: "ControlCenterDiskSmoke"; when: root.target !== null
        function test_smoke_keeps_disk_measuring() { wait(2600); if (root.target.resourceStats.diskActivity !== null || root.target.resourceStats.diskActivityStatus !== "measuring") { console.error("disk polling: smoke mode sampled diskstats"); return Qt.exit(1); } Qt.exit(0); }
    }
}
