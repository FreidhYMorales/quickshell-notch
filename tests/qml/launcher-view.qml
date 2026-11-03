import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher through the centre store, searches the exact name of a
// real desktop entry and looks for that row and a focused search field.
ShellRoot {
    id: root

    property var target: null
    property string name: ""
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    function focusedField(items) {
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.visible && item.cursorPosition !== undefined && item.activeFocus)
                return item;
            const kids = item.children;
            const nested = kids && typeof kids.length === "number" ? focusedField(kids) : null;
            if (nested)
                return nested;
        }
        return null;
    }

    // Desktop entries load lazily: touch them now, read them later.
    Component.onCompleted: DesktopEntries.applications.values.length

    Timer {
        interval: 2500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const entries = DesktopEntries.applications.values.filter(e => !e.noDisplay);
            if (entries.length === 0)
                return Qt.exit(3);
            root.name = entries[0].name;
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "LauncherToggle",
                monitor: screen.name
            });
            root.center.store.dispatch({
                type: "LauncherQuery",
                text: root.name
            });
            check.start();
        }
    }

    Timer {
        id: check

        interval: 800
        onTriggered: {
            if (!root.focusedField(root.target.content)) {
                console.error("launcher view: no focused search field");
                return Qt.exit(1);
            }
            if (!Visual.findText(root.target.content, root.name)) {
                console.error("launcher view: missing row " + root.name);
                return Qt.exit(1);
            }
            console.log("launcher view: field focused, row visible");
            Qt.exit(0);
        }
    }
}
