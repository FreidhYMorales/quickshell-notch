import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ cpu: 37, ram: 62 }) });
        }
    }
    TestCase { name: "ControlCenterResourceValues"; when: root.target !== null
        function test_cpu_ram_values_are_visible() {
            for (const text of ["CPU", "37%", "RAM", "62%"])
                if (!Visual.findText(root.target.content, text)) { console.error("resource view: visible text is missing", text); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
