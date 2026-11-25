import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ cpu: NaN, ram: null }) });
        }
    }
    TestCase { name: "ControlCenterResourcePending"; when: root.target !== null
        function test_unusable_readings_show_status_not_zero() {
            for (const metric of ["CPU", "RAM"]) {
                const label = Visual.findText(root.target.content, metric);
                if (!label || label.parent.children[1].text !== "Measuring…") { console.error("resource view: metric status is missing", metric); return Qt.exit(1); }
            }
            Qt.exit(0);
        }
    }
}
