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
        name: "TrayImageError"
        when: root.target !== null
        function test_error() {
            wait(500);
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            icon.source = "file:///notch-test-nonexistent-image-83db4939.png";
            wait(500);
            if (icon.status !== Image.Error)
                return Qt.exit(2);
            if (!Visual.findText(target.content, "?")) {
                console.error("tray image error: generic symbol not shown");
                return Qt.exit(1);
            }
            console.log("tray image error: generic symbol shown");
            Qt.exit(0);
        }
    }
}
