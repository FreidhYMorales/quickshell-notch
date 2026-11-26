import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ cpu: 37, ram: 62, logicalCpuCount: 8, loadAverage: ({ one: 0.45, five: 0.32, fifteen: 0.12 }) }) });
        }
    }
    TestCase { name: "ControlCenterCpuDetails"; when: root.target !== null
        function test_logical_processors_and_load_averages_are_visible() {
            for (const text of ["Logical CPUs", "8", "Load avg 1/5/15 min", "0.45 · 0.32 · 0.12"])
                if (!Visual.findText(root.target.content, text)) { console.error("CPU details: visible text is missing", text); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
