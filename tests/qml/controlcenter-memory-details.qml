import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ cpu: 37, ram: 50, memoryDetails: ({ usedKiB: 524288, totalKiB: 1048576, availableKiB: 524288, swapUsedKiB: 262144, swapTotalKiB: 524288 }) }) });
        }
    }
    TestCase { name: "ControlCenterMemoryDetails"; when: root.target !== null
        function test_memory_and_swap_are_visible_with_units() {
            for (const text of ["Memory used / total", "512 MiB / 1.0 GiB", "Available memory", "512 MiB", "Swap used / total", "256 MiB / 512 MiB"])
                if (!Visual.findText(root.target.content, text)) { console.error("memory details: visible text is missing", text); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
