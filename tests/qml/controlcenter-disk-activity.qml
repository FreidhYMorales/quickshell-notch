import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 400; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true,
                resourceStats: ({ cpu: 37, ram: 62, diskActivity: ({ device: "nvme0n1p2", readBytesPerSecond: 2560, writeBytesPerSecond: 2048 }), diskActivityStatus: "available" }) });
        }
    }
    TestCase { name: "ControlCenterDiskActivity"; when: root.target !== null
        function test_rates_and_missing_state_are_visible() {
            root.target.showResources();
            for (const text of ["Read rate", "2.5 KiB/s", "Write rate", "2.0 KiB/s"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource details: visible text is missing", text); return Qt.exit(1); }
            root.target.resourceStats = ({ cpu: 37, ram: 62, diskActivity: null, diskActivityStatus: "unavailable" });
            if (!Visual.findText(root.target.content, "Unavailable")) { console.error("resource details: disk status is missing"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
