import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    readonly property var items: SystemTray.items
    property bool ready: false
    QsMenuOpener {
        id: opener
        menu: SystemTray.items.values.length === 1 ? SystemTray.items.values[0].menu : null
    }
    Timer {
        interval: 3500
        running: true
        onTriggered: ready = true
    }
    TestCase {
        name: "TrayMenuEntry"
        when: ready
        function test_entry() {
            if (SystemTray.items.values.length !== 1 || !SystemTray.items.values[0].hasMenu)
                return Qt.exit(2);
            if (opener.children.values.length !== 1 || opener.children.values[0].text !== "Open") {
                console.error("menu fixture: expected one Open option");
                return Qt.exit(1);
            }
            console.log("menu fixture: Open option available");
            Qt.exit(0);
        }
    }
}
