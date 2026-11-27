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
            if (c.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            root.target = c.createObject(null, {
                screen: Quickshell.screens[0],
                open: true,
                view: "resources"
            });
        }
    }
    TestCase {
        name: "ControlCenterResourcePointer"
        when: root.target !== null
        function test_wheel_and_drag_reach_last_resource() {
            const viewport = Visual.findNamed(root.target.content, "cc-resource-grid-viewport");
            if (!viewport || viewport.contentHeight <= viewport.height) {
                console.error("resource view: pointer test has no overflowing viewport");
                return Qt.exit(1);
            }
            const start = viewport.contentY;
            mouseDrag(viewport, viewport.width / 2, viewport.height - 8, 0, -90);
            tryVerify(() => viewport.contentY > start, 1000);
            if (viewport.contentY <= start) {
                console.error("resource view: drag did not scroll the grid");
                return Qt.exit(1);
            }
            const afterDrag = viewport.contentY;
            const wheelPoint = viewport.mapToItem(root.target.maskItem, viewport.width / 2, viewport.height / 2);
            mouseWheel(root.target.maskItem, wheelPoint.x, wheelPoint.y, 0, -120);
            tryVerify(() => viewport.contentY > afterDrag, 1000);
            if (viewport.contentY <= afterDrag) {
                console.error("resource view: wheel did not scroll the grid");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
