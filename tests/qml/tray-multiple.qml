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
            if (component.status !== Component.Ready || SystemTray.items.values.length !== 2)
                return Qt.exit(2);
            target = component.createObject(null, { screen: Quickshell.screens[0] });
            target.step({ type: "Ready" });
            target.step({ type: "TrayHover", count: 2 });
        }
    }
    TestCase {
        name: "TrayMultiple"
        when: root.target !== null
        function test_icons() {
            wait(500);
            const items = SystemTray.items.values;
            const first = Visual.findImage(target.content, items[0].icon);
            const second = Visual.findImage(target.content, items[1].icon);
            if (!first || !second || first === second || first.status !== Image.Ready || second.status !== Image.Ready) {
                console.error("tray multiple: two icons not shown");
                return Qt.exit(1);
            }
            console.log("tray multiple: two icons shown");
            Qt.exit(0);
        }
    }
}
