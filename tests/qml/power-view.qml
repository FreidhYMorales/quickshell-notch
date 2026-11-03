import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the power menu through the centre store and looks for its five icons
// in the centre surface.
ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "PowerOpen",
                monitor: screen.name
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
                    console.error("power view: missing " + icons[i]);
                    return Qt.exit(1);
                }
            }
            console.log("power view: all actions visible");
            root.center.store.dispatch({
                type: "Close",
                monitor: Quickshell.screens[0].name
            });
            Qt.exit(0);
        }
    }
}
