import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, resourceStats: ({ cpu: 37, ram: 62, rootFilesystem: null, rootFilesystemStatus: "measuring" }) });
        }
    }
    TestCase { name: "ControlCenterDiskStatus"; when: root.target !== null
        function test_missing_disk_capacity_states_are_visible() {
            if (!Visual.findText(root.target.content, "DISK") || !Visual.findText(root.target.content, "Measuring…")) { console.error("resource summary: measuring disk state is missing"); return Qt.exit(1); }
            root.target.resourceStats = ({ cpu: 37, ram: 62, rootFilesystem: null, rootFilesystemStatus: "unavailable" });
            if (!Visual.findText(root.target.content, "Unavailable")) { console.error("resource summary: unavailable disk state is missing"); return Qt.exit(1); }
            root.target.showResources();
            for (const text of ["Disk used / total", "Free space", "Unavailable"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource details: unavailable text is missing", text); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
