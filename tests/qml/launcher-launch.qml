import QtQuick
import Quickshell

// Opens the launcher, searches the exact name of a real desktop entry and
// activates the selected row: the app is launched (dry run, only logged) and
// the launcher closes.
ShellRoot {
    id: root

    property var target: null
    property var entry: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    // The launcher view is the visible item that offers launch().
    function launcherView(items) {
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.visible && typeof item.launch === "function")
                return item;
            const kids = item.children;
            const nested = kids && typeof kids.length === "number" ? launcherView(kids) : null;
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
            root.entry = entries[0];
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
                text: root.entry.name
            });
            activate.start();
        }
    }

    Timer {
        id: activate

        interval: 800
        onTriggered: {
            const view = root.launcherView(root.target.content);
            if (!view) {
                console.error("launcher launch: no launcher view");
                return Qt.exit(1);
            }
            console.log("launcher launch: expect " + root.entry.id);
            view.launch(root.center.store.viewFor(Quickshell.screens[0].name).index);
            check.start();
        }
    }

    Timer {
        id: check

        interval: 300
        onTriggered: {
            if (root.center.store.state.global.keyboard !== null) {
                console.error("launcher launch: still open");
                return Qt.exit(1);
            }
            console.log("launcher launch: closed");
            Qt.exit(0);
        }
    }
}
