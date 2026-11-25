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
    TestCase { name: "ControlCenterResourceBack"; when: root.target !== null
        function test_back_returns_to_control_center_root() {
            const back = Visual.findNamed(root.target.content, "cc-resource-back");
            if (!back) { console.error("resource view: back control is missing"); return Qt.exit(1); }
            mouseClick(back);
            tryVerify(() => Visual.findNamed(root.target.content, "cc-resource-entry") !== null, 1000);
            if (!Visual.findNamed(root.target.content, "cc-resource-entry")) { console.error("resource view: back did not return to root"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
