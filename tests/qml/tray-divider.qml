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
            if (component.status !== Component.Ready || SystemTray.items.values.length !== 1)
                return Qt.exit(2);
            target = component.createObject(null, { screen: Quickshell.screens[0] });
            target.step({ type: "Ready" });
            target.step({ type: "TrayHover", count: 1 });
        }
    }
    TestCase {
        name: "TrayDivider"
        when: root.target !== null
        function test_divider() {
            wait(500);
            const arch = Visual.findText(target.content, "\uf303");
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!arch || !icon)
                return Qt.exit(2);
            const divider = Visual.findVerticalDivider(target.content);
            if (!divider || divider.mapToItem(null, 0, 0).x <= arch.mapToItem(null, 0, 0).x + arch.width || divider.mapToItem(null, 0, 0).x >= icon.mapToItem(null, 0, 0).x) {
                console.error("tray divider: no separator between Arch and tray");
                return Qt.exit(1);
            }
            console.log("tray divider: separator is visible");
            Qt.exit(0);
        }
    }
}
