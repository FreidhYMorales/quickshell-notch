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
        name: "TrayClose"
        when: root.target !== null
        function test_close() {
            wait(500);
            const source = SystemTray.items.values[0].icon;
            if (!Visual.findImage(root.target.content, source))
                return Qt.exit(2);
            root.target.step({ type: "Hover", on: false });
            root.target.step({ type: "Timeout" });
            if (!Visual.findImage(root.target.content, source) || Visual.findText(root.target.content, "●")) {
                console.error("tray close: row changes during exit");
                return Qt.exit(1);
            }
            wait(500);
            root.target.step({ type: "Trigger" });
            if (!Visual.findText(root.target.content, "●") || Visual.findImage(root.target.content, source))
                return Qt.exit(1);
            console.log("tray close: row changes after exit");
            Qt.exit(0);
        }
    }
}
