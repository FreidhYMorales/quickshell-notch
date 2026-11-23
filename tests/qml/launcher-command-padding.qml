import QtQuick
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Timer {
        interval: 2500; running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || !Quickshell.screens.length) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">" });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 800
        onTriggered: {
            const list = Visual.findNamed(root.target.content, "launcher-results-command-list");
            if (!list || list.count !== 6) {
                console.error("launcher padding: expected all six commands");
                return Qt.exit(2);
            }
            const first = list.itemAtIndex(0);
            if (!first) {
                console.error("launcher padding: first command row is not instantiated");
                return Qt.exit(2);
            }
            const rows = list.height / first.height;
            if (Math.abs(rows - 5) > 0.01 || list.contentHeight <= list.height) {
                console.error("launcher padding: expected a five-row scroll viewport, got " + rows);
                return Qt.exit(1);
            }
            console.log("launcher padding: six commands in a five-row viewport");
            Qt.exit(0);
        }
    }
}
