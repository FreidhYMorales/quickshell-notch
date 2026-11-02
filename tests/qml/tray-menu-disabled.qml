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
        name: "TrayMenuDisabled"
        when: root.target !== null
        function test_disabled() {
            wait(500);
            const icon = Visual.findImage(root.target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const open = Visual.findText(root.target.content, "Open");
            const disabled = Visual.findText(root.target.content, "Disabled");
            if (!open || !disabled)
                return Qt.exit(2);
            if (String(disabled.color) === String(open.color)) {
                console.error("tray menu: disabled option looks enabled");
                return Qt.exit(1);
            }
            mouseClick(disabled, disabled.width / 2, disabled.height / 2);
            wait(500);
            console.log("tray menu: disabled clicked");
            Qt.exit(0);
        }
    }
}
