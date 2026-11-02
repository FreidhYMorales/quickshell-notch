import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    property var target: null

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            if (component.status !== Component.Ready || SystemTray.items.values.length !== 1) {
                console.error("tray hover setup: " + component.errorString());
                Qt.exit(2);
                return;
            }
            root.target = component.createObject(null, { screen: Quickshell.screens[0] });
            if (!root.target)
                Qt.exit(2);
        }
    }

    TestCase {
        name: "TrayHover"
        when: root.target !== null
        function test_hover() {
            wait(1300);
            mouseMove(root.target.maskItem, 1, 1);
            wait(1000);
            if (!root.target.open) {
                console.error("tray hover: notch did not open");
                Qt.exit(1);
                return;
            }
            console.log("tray hover: notch opened");
            Qt.exit(0);
        }
    }
}
