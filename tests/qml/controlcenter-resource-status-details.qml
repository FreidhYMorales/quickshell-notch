import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, {
                screen: Quickshell.screens[0],
                open: true,
                view: "resources",
                resourceStats: ({
                    cpu: 37, cpuStatus: "invalid",
                    ram: null, ramStatus: "unavailable",
                    logicalCpuCount: null, logicalCpuCountStatus: "unavailable",
                    loadAverage: null, loadAverageStatus: "invalid",
                    memoryDetails: {
                        usedKiB: 1024, totalKiB: 2048, availableKiB: 1024,
                        swapUsedKiB: null, swapTotalKiB: null
                    },
                    memoryDetailsStatus: "available",
                    memorySwapStatus: "unavailable",
                    rootFilesystem: null, rootFilesystemStatus: "invalid",
                    diskActivity: null, diskActivityStatus: "invalid",
                    networkActivity: null, networkActivityStatus: "measuring"
                })
            });
        }
    }
    TestCase {
        name: "ControlCenterResourceStatusDetails"
        when: root.target !== null
        function test_detail_statuses_override_stale_values_and_preserve_siblings() {
            for (const [label, expected] of [
                ["CPU", "Invalid reading"],
                ["RAM", "Unavailable"],
                ["Logical CPUs", "Unavailable"],
                ["Load avg 1/5/15 min", "Invalid reading"],
                ["Memory used / total", "1 MiB / 2 MiB"],
                ["Available memory", "1 MiB"],
                ["Swap used / total", "Unavailable"],
                ["Disk used / total", "Invalid reading"],
                ["Free space", "Invalid reading"],
                ["Read rate", "Invalid reading"],
                ["Receive rate", "Measuring…"]
            ]) {
                if (!Visual.findText(root.target.content, label) || !Visual.findText(root.target.content, expected)) {
                    console.error("resource details:", label, "expected", expected);
                    return Qt.exit(1);
                }
            }
            if (Visual.findText(root.target.content, "37%")) {
                console.error("resource details: stale CPU value was displayed");
                return Qt.exit(1);
            }
            root.target.resourceStats = Object.assign({}, root.target.resourceStats, {
                cpu: 0, cpuStatus: "available",
                ram: 0, ramStatus: "available"
            });
            if (!Visual.findText(root.target.content, "0%")) {
                console.error("resource details: valid zero was not displayed");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
