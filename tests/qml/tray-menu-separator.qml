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
        name: "TrayMenuSeparator"
        when: root.target !== null
        function marks(text, label) {
            const found = [];
            for (const t of Visual.textsIn(text.parent))
                if (t !== label)
                    found.push(t);
            return found;
        }
        function test_separator_and_check() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const open = Visual.findText(root.target.content, "Open");
            const checked = Visual.findText(root.target.content, "Checked");
            const unchecked = Visual.findText(root.target.content, "Unchecked");
            if (!open || !checked || !unchecked) {
                console.error("tray menu: typed options not shown");
                return Qt.exit(2);
            }
            const divider = Visual.findHorizontalDivider(root.target.content);
            if (!divider) {
                console.error("tray menu: separator not drawn as a divider");
                return Qt.exit(1);
            }
            if (divider.width < divider.height * 20) {
                console.error("tray menu: separator divider too short: " + divider.width);
                return Qt.exit(1);
            }
            const checkedMarks = marks(checked, "Checked");
            if (checkedMarks.length !== 1 || checkedMarks[0].length > 3) {
                console.error("tray menu: checked option marks: " + checkedMarks.length);
                return Qt.exit(1);
            }
            const uncheckedMarks = marks(unchecked, "Unchecked");
            if (uncheckedMarks.length !== 0) {
                console.error("tray menu: unchecked option marks: " + uncheckedMarks.length);
                return Qt.exit(1);
            }
            console.log("tray menu: separator and check shown");
            Qt.exit(0);
        }
    }
}
