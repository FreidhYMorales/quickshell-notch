import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuHeader"
        when: setup.target !== null
        function test_header() {
            wait(500);
            const target = setup.target;
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const option = Visual.findText(target.content, "Item 1");
            const divider = Visual.findHorizontalDivider(target.content);
            if (!option || !divider) {
                console.error("tray menu: missing header separator or option");
                return Qt.exit(1);
            }
            const y = divider.mapToItem(null, 0, 0).y;
            if (y < icon.mapToItem(null, 0, 0).y + icon.height || y + divider.height > option.mapToItem(null, 0, 0).y) {
                console.error("tray menu: separator not between icon and option");
                return Qt.exit(1);
            }
            for (let i = 0; i < 20; i++) {
                mouseWheel(target.maskItem, 40, 100, 0, -120);
                wait(50);
            }
            if (divider.mapToItem(null, 0, 0).y !== y) {
                console.error("tray menu: header separator scrolled away");
                return Qt.exit(1);
            }
            console.log("tray menu: header separator stays fixed");
            Qt.exit(0);
        }
    }
}
