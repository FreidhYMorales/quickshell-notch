import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    id: root
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuIndicator"
        when: setup.target !== null
        function test_indicator() {
            wait(500);
            const target = setup.target;
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            if (!Visual.findText(target.content, "\uf078")) {
                console.error("tray menu: missing more-options indicator");
                return Qt.exit(1);
            }
            for (let i = 0; i < 40; i++) {
                mouseWheel(target.maskItem, 40, 100, 0, -120);
                wait(50);
            }
            wait(500);
            if (Visual.findText(target.content, "\uf078")) {
                console.error("tray menu: indicator remains at end");
                return Qt.exit(1);
            }
            console.log("tray menu: more-options indicator works");
            Qt.exit(0);
        }
    }
}
