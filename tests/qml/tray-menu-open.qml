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
        name: "TrayMenuOpen"
        when: root.target !== null
        function test_open() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon || Visual.findText(root.target.content, "Open"))
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            if (!Visual.findText(root.target.content, "Open")) {
                console.error("tray menu: Open option not shown after right-click");
                return Qt.exit(1);
            }
            console.log("tray menu: Open option shown");
            Qt.exit(0);
        }
    }
}
