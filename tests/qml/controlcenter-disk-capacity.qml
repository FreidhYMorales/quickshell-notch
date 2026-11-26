import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, resourceStats: ({ cpu: 37, ram: 62, rootFilesystem: ({ totalBytes: 10737418240, usedBytes: 3221225472, availableBytes: 7516192768, usedPercent: 30 }) }) });
        }
    }
    TestCase { name: "ControlCenterDiskCapacity"; when: root.target !== null
        function test_disk_capacity_is_visible_in_summary_and_details() {
            for (const text of ["DISK", "30%"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource summary: visible text is missing", text); return Qt.exit(1); }
            root.target.showResources();
            for (const text of ["Disk used / total", "3.0 GiB / 10.0 GiB", "Free space", "7.0 GiB"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource details: visible text is missing", text); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
