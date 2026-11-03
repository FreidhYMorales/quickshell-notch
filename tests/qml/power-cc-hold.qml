import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Clicks reboot, then (after closing the menu and reopening) poweroff in the
// control center's power row and reports the panel and power menu state.
ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "PowerCcHold"
        when: true

        function clickAction(icon) {
            const screen = Quickshell.screens[0];
            root.center.store.dispatch({
                type: "Close",
                monitor: screen.name
            });
            root.target.open = true;
            wait(600);
            const item = Visual.findText(root.target.content, icon);
            if (!item) {
                console.error("cc hold: missing " + icon);
                return Qt.exit(1);
            }
            mouseClick(item, item.width / 2, item.height / 2);
            wait(300);
            const keyboard = root.center.store.state.global.keyboard;
            console.log("cc hold: " + icon + " open " + root.target.open + " menu " + JSON.stringify(keyboard) + " on " + screen.name);
        }

        function test_hold() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) {
                console.error("cc hold: setup failed");
                return Qt.exit(2);
            }
            root.target = component.createObject(null, {
                screen: Quickshell.screens[0]
            });
            clickAction("󰜉");
            clickAction("⏻");
            root.center.store.dispatch({
                type: "Close",
                monitor: Quickshell.screens[0].name
            });
            Qt.exit(0);
        }
    }
}
