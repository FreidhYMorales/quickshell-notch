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
        name: "TrayMenuHover"
        when: root.target !== null
        function test_hover() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const option = Visual.findText(root.target.content, "Open");
            const arch = Visual.findText(root.target.content, "\uf303");
            if (!option || !arch) {
                console.error("tray menu: option or primary reference not shown");
                return Qt.exit(2);
            }
            // Park the pointer on the icon: a row that appears under a still
            // pointer can report itself hovered, and only a move clears it.
            mouseMove(icon, 1, 1);
            wait(300);
            const parked = Visual.findText(root.target.content, "Open");
            const normal = Qt.rgba(parked.color.r, parked.color.g, parked.color.b, parked.color.a);
            console.log("tray menu: normal " + normal);
            if (normal.r < 0.75 || normal.g < 0.75 || normal.b < 0.75) {
                console.error("tray menu: option text is not light");
                return Qt.exit(1);
            }
            mouseMove(parked, parked.width / 2, parked.height / 2);
            wait(300);
            const hovered = Visual.findText(root.target.content, "Open");
            const accent = Visual.findText(root.target.content, "\uf303");
            if (Qt.colorEqual(hovered.color, normal)) {
                console.error("tray menu: hover did not change the option colour");
                return Qt.exit(1);
            }
            if (!Qt.colorEqual(hovered.color, accent.color)) {
                console.error("tray menu: hover is not the primary colour");
                return Qt.exit(1);
            }
            console.log("tray menu: hover ok");
            Qt.exit(0);
        }
    }
}
