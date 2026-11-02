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
        name: "TrayOpenPriority"
        when: root.target !== null
        function test_priority() {
            wait(500);
            const source = SystemTray.items.values[0].icon;
            if (!Visual.findImage(root.target.content, source))
                return Qt.exit(2);
            root.target.step({ type: "Trigger" });
            root.target.step({ type: "Trigger", flash: { workspaceId: 1, cls: "Steam" } });
            wait(100);
            if (!root.target.open || !Visual.findImage(root.target.content, source) || Visual.findText(root.target.content, "●")) {
                console.error("tray priority: activity replaced open tray");
                return Qt.exit(1);
            }
            console.log("tray priority: open tray preserved");
            Qt.exit(0);
        }
    }
}
