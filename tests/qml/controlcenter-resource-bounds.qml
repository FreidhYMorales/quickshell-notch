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
        name: "ControlCenterResourceBounds"
        when: root.target !== null
        function test_all_resource_cards_fit_a_fixed_viewport() {
            const viewport = Visual.findNamed(root.target.content, "cc-resource-grid-viewport");
            if (!viewport || !viewport.clip || viewport.contentHeight <= viewport.height) {
                console.error("resource view: clipped scrolling viewport is missing or does not contain the complete grid");
                return Qt.exit(1);
            }
            if (!Visual.findText([viewport], "Transmit rate") || !Visual.findText([viewport], "Load average")) {
                console.error("resource view: resource cards are missing from the complete grid");
                return Qt.exit(1);
            }
            if (root.target.height >= root.target.screen.availableGeometry.height) {
                console.error("resource view: panel exceeds monitor safe height");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
