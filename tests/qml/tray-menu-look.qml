import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    readonly property int margin: 16
    readonly property int bottomMargin: 4
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
        name: "TrayMenuLook"
        when: root.target !== null
        function test_look() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const option = Visual.findText(root.target.content, "Open");
            if (!option) {
                console.error("tray menu: Open option not shown");
                return Qt.exit(2);
            }
            const size = root.target.size;
            const pos = option.mapToItem(null, 0, 0);
            const left = pos.x;
            const right = size.width - (pos.x + option.width);
            const bottom = size.height - (pos.y + option.height);
            console.log("tray menu: width " + size.width + ", margins " + left + "/" + right + "/" + bottom);
            if (size.width > 200) {
                console.error("tray menu: short menu is " + size.width + " wide");
                return Qt.exit(1);
            }
            if (left < root.margin) {
                console.error("tray menu: left margin is " + left);
                return Qt.exit(1);
            }
            if (right < root.margin) {
                console.error("tray menu: right margin is " + right);
                return Qt.exit(1);
            }
            if (bottom < root.bottomMargin) {
                console.error("tray menu: bottom margin is " + bottom);
                return Qt.exit(1);
            }
            console.log("tray menu: layout ok");
            Qt.exit(0);
        }
    }
}
