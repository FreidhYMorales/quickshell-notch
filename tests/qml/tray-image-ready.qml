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
        name: "TrayImageReady"
        when: root.target !== null
        function test_image() {
            wait(500);
            const source = SystemTray.items.values[0].icon;
            const image = Visual.findImage(target.content, source);
            if (!source.startsWith("image://qspixmap/") || !image || image.status !== Image.Ready) {
                console.error("tray image: expected pixmap not ready");
                return Qt.exit(1);
            }
            console.log("tray image: expected pixmap ready");
            Qt.exit(0);
        }
    }
}
