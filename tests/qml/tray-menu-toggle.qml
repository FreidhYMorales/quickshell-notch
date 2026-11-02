import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    property var target: null
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            if (component.status !== Component.Ready || SystemTray.items.values.length !== 1 || !SystemTray.items.values[0].hasMenu)
                return Qt.exit(2);
            target = component.createObject(null, { screen: Quickshell.screens[0] });
            target.step({ type: "Ready" });
            target.step({ type: "TrayHover", count: 1 });
        }
    }
    TestCase {
        name: "TrayMenuToggle"
        when: root.target !== null
        function test_toggle() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            if (!Visual.findText(root.target.content, "Open")) {
                console.error("tray menu: option not shown on first click");
                return Qt.exit(1);
            }
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            if (Visual.findText(root.target.content, "Open")) {
                console.error("tray menu: option still shown after second click");
                return Qt.exit(1);
            }
            console.log("tray menu: second click closes menu");
            Qt.exit(0);
        }
    }
}
