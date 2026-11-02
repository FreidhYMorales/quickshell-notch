import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuWidth"
        when: setup.target !== null
        function test_width() {
            wait(500);
            const target = setup.target;
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon || target.menuItem !== null)
                return Qt.exit(2);
            const initialWidth = target.size.width;
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            if (!Visual.findText(target.content, "Item 1"))
                return Qt.exit(2);
            if (target.size.width <= initialWidth) {
                console.error("tray menu: width did not grow: " + initialWidth + " -> " + target.size.width);
                return Qt.exit(1);
            }
            console.log("tray menu: width grows for options");
            Qt.exit(0);
        }
    }
}
