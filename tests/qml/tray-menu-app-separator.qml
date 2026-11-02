import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuAppSeparator"
        when: setup.target !== null
        function test_separator() {
            wait(500);
            const target = setup.target;
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const before = Visual.findText(target.content, "Open");
            const after = Visual.findText(target.content, "Checked");
            if (!before || !after)
                return Qt.exit(2);
            const column = before.parent.parent.parent;
            const divider = Visual.findHorizontalDivider(column.children);
            if (!divider) {
                console.error("tray menu: missing app-provided separator");
                return Qt.exit(1);
            }
            const y = divider.mapToItem(null, 0, 0).y;
            if (y < before.mapToItem(null, 0, 0).y + before.height || y + divider.height > after.mapToItem(null, 0, 0).y) {
                console.error("tray menu: app separator not between options");
                return Qt.exit(1);
            }
            console.log("tray menu: app separator between options");
            Qt.exit(0);
        }
    }
}
