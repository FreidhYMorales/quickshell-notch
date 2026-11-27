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
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "root",
                resourceStats: ({ cpu: null, cpuStatus: "measuring", ram: null, ramStatus: "unavailable",
                    rootFilesystem: null, rootFilesystemStatus: "invalid" }) });
        }
    }
    TestCase {
        name: "ControlCenterResourceStatusSummary"
        when: root.target !== null
        function test_summary_states_and_valid_zero() {
            function valueFor(label) {
                const item = Visual.findText(root.target.content, label);
                return item ? item.parent.children[1].text : null;
            }
            for (const [label, expected] of [["CPU", "Measuring…"], ["RAM", "Unavailable"], ["DISK", "Invalid reading"]]) {
                if (valueFor(label) !== expected) {
                    console.error("resource summary:", label, "expected", expected, "got", valueFor(label));
                    return Qt.exit(1);
                }
            }
            root.target.resourceStats = ({ cpu: 0, cpuStatus: "available", ram: 0, ramStatus: "available",
                rootFilesystem: ({ usedPercent: 0 }), rootFilesystemStatus: "available" });
            for (const label of ["CPU", "RAM", "DISK"])
                if (valueFor(label) !== "0%") { console.error("resource summary: valid zero was not displayed", label); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
