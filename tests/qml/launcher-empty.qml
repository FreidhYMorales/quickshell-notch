import QtQuick
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher: "No matches" stays hidden while apps are listed and
// shows once the query matches nothing.
ShellRoot {
    id: root

    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    // Desktop entries load lazily: touch them now, read them later.
    Component.onCompleted: DesktopEntries.applications.values.length

    Timer {
        interval: 2500
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
            listed.start();
        }
    }

    Timer {
        id: listed

        interval: 800
        onTriggered: {
            if (Visual.findText(root.target.content, "No matches")) {
                console.error("launcher empty: shown while apps are listed");
                return Qt.exit(1);
            }
            root.center.store.dispatch({
                type: "LauncherQuery",
                text: "zqxjzqxj"
            });
            empty.start();
        }
    }

    Timer {
        id: empty

        interval: 300
        onTriggered: {
            if (!Visual.findText(root.target.content, "No matches")) {
                console.error("launcher empty: missing No matches");
                return Qt.exit(1);
            }
            console.log("launcher empty: No matches shown");
            Qt.exit(0);
        }
    }
}
