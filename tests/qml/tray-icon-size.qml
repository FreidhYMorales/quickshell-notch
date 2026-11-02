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
        name: "TrayIconSize"
        when: root.target !== null
        function test_size() {
            wait(500);
            const arch = Visual.findText(target.content, "\uf303");
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!arch || !icon)
                return Qt.exit(2);
            if (Math.abs(icon.paintedHeight - arch.paintedHeight) > 1) {
                console.error("tray size: icon=" + icon.paintedHeight + " arch=" + arch.paintedHeight);
                return Qt.exit(1);
            }
            console.log("tray size: icon matches Arch");
            Qt.exit(0);
        }
    }
}
