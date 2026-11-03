import QtQuick
import Quickshell

// Opens the launcher, types into its focused field and checks that the centre
// store received the text as the launcher query.
ShellRoot {
    id: root

    property var target: null
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
                type: "LauncherToggle",
                monitor: screen.name
            });
            type.start();
        }
    }

    Timer {
        id: type

        interval: 500
        onTriggered: {
            const field = root.focusedField(root.target.content);
            if (!field) {
                console.error("launcher typing: no focused field");
                return Qt.exit(1);
            }
            field.insert(0, "fire");
            check.start();
        }
    }

    Timer {
        id: check

        interval: 300
        onTriggered: {
            const query = root.center.store.viewFor(Quickshell.screens[0].name).query;
            if (query !== "fire") {
                console.error("launcher typing: store query is " + JSON.stringify(query));
                return Qt.exit(1);
            }
            console.log("launcher typing: query reached the store");
            Qt.exit(0);
        }
    }
}
