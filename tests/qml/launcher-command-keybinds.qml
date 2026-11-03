import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">key" });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 800
        onTriggered: {
            if (!Visual.findText(root.target.content, "View keyboard shortcuts.")) {
                console.error("launcher commands: keybinds description missing");
                return Qt.exit(1);
            }
            console.log("launcher commands: keybinds description shown");
            Qt.exit(0);
        }
    }
}
