import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    id: root
    readonly property var items: SystemTray.items
    property var target: null
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            root.target = component.createObject(null, { screen: Quickshell.screens[0] });
        }
    }
    TestCase {
        name: "EmptyTray"
        when: root.target !== null
        function test_hover() {
            wait(1300);
            if (SystemTray.items.values.length !== 0)
                return Qt.exit(2);
            mouseMove(root.target.maskItem, 1, 1);
            wait(500);
            if (root.target.open || root.target.maskItem.width !== 0 || root.target.maskItem.height !== 0) {
                console.error("empty tray: corner is not click-through");
                return Qt.exit(1);
            }
            console.log("empty tray: corner stays hidden and click-through");
            Qt.exit(0);
        }
    }
}
