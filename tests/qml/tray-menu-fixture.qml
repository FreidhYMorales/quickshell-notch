import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    readonly property var items: SystemTray.items
    property bool ready: false

    Timer {
        interval: 3000
        running: true
        onTriggered: ready = true
    }

    TestCase {
        name: "TrayMenuFixture"
        when: ready
        function test_menu_advertised() {
            if (SystemTray.items.values.length !== 1) {
                console.error("menu fixture setup: expected one tray item");
                return Qt.exit(2);
            }
            if (!SystemTray.items.values[0].hasMenu) {
                console.error("menu fixture: item does not advertise a menu");
                return Qt.exit(1);
            }
            console.log("menu fixture: menu advertised");
            Qt.exit(0);
        }
    }
}
