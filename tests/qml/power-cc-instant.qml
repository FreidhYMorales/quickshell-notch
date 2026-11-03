import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Clicks lock, then (after reopening) suspend in the control center's power
// row and reports whether the panel collapsed after each click.
ShellRoot {
    id: root

    property var target: null

    TestCase {
        name: "PowerCcInstant"
        when: true

        function clickAction(icon) {
            root.target.open = true;
            wait(600);
            const item = Visual.findText(root.target.content, icon);
            if (!item) {
                console.error("cc instant: missing " + icon);
                return Qt.exit(1);
            }
            mouseClick(item, item.width / 2, item.height / 2);
            wait(300);
            console.log("cc instant: " + icon + " open after click " + root.target.open);
        }

        function test_instant() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) {
                console.error("cc instant: setup failed");
                return Qt.exit(2);
            }
            root.target = component.createObject(null, {
                screen: Quickshell.screens[0]
            });
            clickAction("󰌾");
            clickAction("󰤄");
            Qt.exit(0);
        }
    }
}
