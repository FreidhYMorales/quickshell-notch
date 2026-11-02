import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    readonly property var items: SystemTray.items

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const list = SystemTray.items.values;
            if (list.length !== 1 || list[0].title !== "QS Test App") {
                console.error("notch-tray-test: simulated item not detected");
                Qt.exit(1);
                return;
            }
            console.log("notch-tray-test: simulated item detected");
            Qt.exit(0);
        }
    }
}
