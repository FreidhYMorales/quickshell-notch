import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the power menu (nothing preselected), moves the pointer over the
// reboot icon and reports which action ended up selected.
ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "PowerHover"
        when: true

        function test_hover() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) {
                console.error("power hover: setup failed");
                return Qt.exit(2);
            }
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "PowerOpen",
                monitor: screen.name
            });
            wait(600);
            const icon = Visual.findText(root.target.content, "󰜉");
            if (!icon) {
                console.error("power hover: reboot icon missing");
                return Qt.exit(1);
            }
            mouseMove(icon, icon.width / 2, icon.height / 2);
            wait(300);
            console.log("power hover: selected " + root.center.store.state.global.keyboard?.sub);
            root.center.store.dispatch({
                type: "Close",
                monitor: screen.name
            });
            Qt.exit(0);
        }
    }
}
