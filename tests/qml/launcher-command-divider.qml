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
            const divider = Visual.findVerticalDivider(root.target.content);
            const name = Visual.findText(root.target.content, "Keybinds");
            const description = Visual.findText(root.target.content, "View keyboard shortcuts.");
            if (!divider || !name || !description) { console.error("launcher divider: missing content or divider"); return Qt.exit(1); }
            const left = name.mapToItem(divider.parent, name.width, 0).x;
            const right = description.mapToItem(divider.parent, 0, 0).x;
            if (left >= divider.x || divider.x + divider.width >= right) { console.error("launcher divider: wrong position"); return Qt.exit(1); }
            console.log("launcher divider: between list and description");
            Qt.exit(0);
        }
    }
}
