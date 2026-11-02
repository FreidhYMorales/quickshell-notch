import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    // Strings.glyphChevronLeft: the control that returns to the previous menu.
    readonly property string backGlyph: "\uf053"
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
        name: "TrayMenuSubmenu"
        when: root.target !== null
        function test_submenu() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const open = Visual.findText(root.target.content, "Open");
            const more = Visual.findText(root.target.content, "More");
            if (!open || !more) {
                console.error("tray menu: root options not shown");
                return Qt.exit(2);
            }
            mouseClick(more, more.width / 2, more.height / 2);
            wait(500);
            const nested = Visual.findText(root.target.content, "Nested A");
            if (!nested) {
                console.error("tray menu: submenu options not shown");
                return Qt.exit(1);
            }
            if (Visual.findText(root.target.content, "Open")) {
                console.error("tray menu: root options still shown in the submenu");
                return Qt.exit(1);
            }
            const back = Visual.findText(root.target.content, root.backGlyph);
            if (!back) {
                console.error("tray menu: no back control in the submenu");
                return Qt.exit(1);
            }
            mouseClick(back, back.width / 2, back.height / 2);
            wait(500);
            if (!Visual.findText(root.target.content, "Open")) {
                console.error("tray menu: back did not restore the root options");
                return Qt.exit(1);
            }
            if (Visual.findText(root.target.content, "Nested A")) {
                console.error("tray menu: submenu options still shown after back");
                return Qt.exit(1);
            }
            console.log("tray menu: submenu replaced and back restored");
            Qt.exit(0);
        }
    }
}
