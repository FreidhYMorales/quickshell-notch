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
        name: "TrayMenuSize"
        when: root.target !== null
        function test_size() {
            wait(500);
            const cap = Math.floor(Quickshell.screens[0].height / 2);
            const count = parseInt(Quickshell.env("NOTCH_TEST_MENU_COUNT") || "1", 10);
            const idle = root.target.size.height;
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const height = root.target.size.height;
            console.log("tray menu size: height " + height + ", idle " + idle + ", cap " + cap + ", count " + count);
            if (height <= idle) {
                console.error("tray menu size: notch did not grow past " + idle);
                return Qt.exit(1);
            }
            if (height > cap) {
                console.error("tray menu size: notch exceeds " + cap);
                return Qt.exit(1);
            }
            if (count > 10 && height !== cap) {
                console.error("tray menu size: notch stopped at " + height + " before " + cap);
                return Qt.exit(1);
            }
            if (count <= 10 && height === cap) {
                console.error("tray menu size: short menu filled the whole " + cap);
                return Qt.exit(1);
            }
            console.log("tray menu size: ok");
            Qt.exit(0);
        }
    }
}
