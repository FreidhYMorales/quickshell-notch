import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the control center and looks for the five power icons.
ShellRoot {
    id: root

    property var target: null

    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            root.target = component.createObject(null, {
                screen: Quickshell.screens[0],
                open: true
            });
            check.start();
        }
    }

    Timer {
        id: check

        interval: 500
        onTriggered: {
            const icons = ["󰌾", "󰤄", "󰍃", "󰜉", "⏻"];
            for (let i = 0; i < icons.length; i++) {
                if (!Visual.findText(root.target.content, icons[i])) {
                    console.error("cc power row: missing " + icons[i]);
                    return Qt.exit(1);
                }
            }
            console.log("cc power row: all actions visible");
            Qt.exit(0);
        }
    }
}
