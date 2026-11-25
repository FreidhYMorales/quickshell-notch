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
    TestCase { name: "ControlCenterResourceEscape"; when: root.target !== null
        function test_escape_returns_to_control_center_root() {
            if (!root.target.wantsKeyboard) { console.error("resource view: keyboard focus is not enabled"); return Qt.exit(1); }
            keyClick(Qt.Key_Escape);
            tryVerify(() => root.target.view === "root", 1000);
            if (root.target.view !== "root") { console.error("resource view: Escape did not return to root"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
