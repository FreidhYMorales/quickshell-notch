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
        name: "TraySwitch"
        when: root.target !== null
        function test_switch() {
            wait(500);
            const arch = Visual.findText(root.target.content, "\uf303");
            if (!arch || Visual.findText(root.target.content, "●"))
                return Qt.exit(2);
            mouseClick(arch, arch.width / 2, arch.height / 2, Qt.RightButton);
            wait(300);
            if (!Visual.findText(root.target.content, "●")) {
                console.error("tray switch: workspace row not shown");
                return Qt.exit(1);
            }
            mouseClick(arch, arch.width / 2, arch.height / 2, Qt.RightButton);
            wait(300);
            if (Visual.findText(root.target.content, "●"))
                return Qt.exit(1);
            console.log("tray switch: rows alternate");
            Qt.exit(0);
        }
    }
}
