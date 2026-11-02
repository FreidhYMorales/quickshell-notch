import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "visual.mjs" as Visual

ShellRoot {
    TrayMenuSetup { id: setup }
    TestCase {
        name: "TrayMenuCheckmark"
        when: setup.target !== null
        function test_checkmark() {
            wait(500);
            const target = setup.target;
            const icon = Visual.findImage(target.content, SystemTray.items.values[0].icon);
            if (!icon)
                return Qt.exit(2);
            mouseClick(icon, icon.width / 2, icon.height / 2, Qt.RightButton);
            wait(500);
            const checked = Visual.findText(target.content, "Checked");
            const unchecked = Visual.findText(target.content, "Unchecked");
            if (!checked || !unchecked)
                return Qt.exit(2);
            const checkedTexts = Visual.textsIn(checked.parent);
            const uncheckedTexts = Visual.textsIn(unchecked.parent);
            if (checkedTexts.indexOf("\uf00c") < 0 || uncheckedTexts.indexOf("\uf00c") >= 0) {
                console.error("tray menu: incorrect check mark");
                return Qt.exit(1);
            }
            console.log("tray menu: exact check mark shown only when checked");
            Qt.exit(0);
        }
    }
}
