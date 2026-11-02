import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    readonly property var target: setup.target
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuScroll"
        when: root.target !== null
        function test_scroll() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const last = Visual.findText(root.target.content, "Item 30");
            if (!last)
                return Qt.exit(2);
            const initialY = last.mapToItem(null, 0, 0).y;
            const iconY = icon.mapToItem(null, 0, 0).y;
            for (let i = 0; i < 40; i++) {
                mouseWheel(root.target.maskItem, 40, 100, 0, -120);
                wait(50);
            }
            wait(500);
            const finalY = last.mapToItem(null, 0, 0).y;
            if (finalY < iconY || finalY + last.height > root.target.size.height || finalY >= initialY || icon.mapToItem(null, 0, 0).y !== iconY) {
                console.error("tray menu: scrolling failed: " + initialY + " -> " + finalY);
                return Qt.exit(1);
            }
            console.log("tray menu: last option reachable while icons stay fixed");
            Qt.exit(0);
        }
    }
}
