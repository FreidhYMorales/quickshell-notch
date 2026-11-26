import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ cpu: 37, ram: 50, logicalCpuCount: null, logicalCpuCountStatus: "unavailable", loadAverage: null, loadAverageStatus: "measuring", memoryDetails: null, memoryDetailsStatus: "unavailable" }) });
        }
    }
    TestCase { name: "ControlCenterDetailsStatus"; when: root.target !== null
        function test_missing_details_show_status_not_zero() {
            for (const text of ["Logical CPUs", "Unavailable", "Load avg 1/5/15 min", "Measuring…", "Memory used / total", "Available memory", "Swap used / total"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource details: visible text is missing", text); return Qt.exit(1); }
            if (Visual.findText(root.target.content, "0")) { console.error("resource details: missing value was shown as zero"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
