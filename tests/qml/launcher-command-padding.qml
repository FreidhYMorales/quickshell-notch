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
            const text = Visual.findText(root.target.content, "Wallpaper");
            if (!text) {
                console.error("launcher padding: missing last command");
                return Qt.exit(2);
            }
            const row = text.parent.parent;
            const list = row.parent.parent;
            // The last row by index, whichever command ends the list.
            const last = list.itemAtIndex(list.count - 1);
            if (!last) {
                console.error("launcher padding: no last row");
                return Qt.exit(2);
            }
            const blank = list.height - last.mapToItem(list, 0, last.height).y;
            if (Math.abs(blank) > 1) { console.error("launcher padding: empty space " + blank); return Qt.exit(1); }
            console.log("launcher padding: no empty rows");
            Qt.exit(0);
        }
    }
}
