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
        name: "TrayClosingPriority"
        when: root.target !== null
        function test_priority() {
            wait(500);
            const source = SystemTray.items.values[0].icon;
            if (!Visual.findImage(root.target.content, source))
                return Qt.exit(2);
            root.target.step({ type: "Hover", on: false });
            root.target.step({ type: "Timeout" });
            root.target.step({ type: "Trigger" });
            wait(100);
            if (!Visual.findImage(root.target.content, source) || Visual.findText(root.target.content, "●") || root.target.open) {
                console.error("tray priority: workspace interrupted exit");
                return Qt.exit(1);
            }
            wait(500);
            root.target.step({ type: "Trigger" });
            if (!Visual.findText(root.target.content, "●"))
                return Qt.exit(1);
            console.log("tray priority: exit preserved; next workspace shown");
            Qt.exit(0);
        }
    }
}
