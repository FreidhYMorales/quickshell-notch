import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            root.target = component.createObject(null, { screen: Quickshell.screens[0], open: true });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 500
        onTriggered: {
            if (!Visual.findText(root.target.content, "󰻃")) {
                console.error("recording control: missing");
                return Qt.exit(1);
            }
            console.log("recording control: visible");
            Qt.exit(0);
        }
    }
}
