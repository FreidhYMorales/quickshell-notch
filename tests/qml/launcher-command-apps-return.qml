import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property string appName: ""
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Component.onCompleted: DesktopEntries.applications.values.length

    Timer {
        interval: 2500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const entries = DesktopEntries.applications.values.filter(e => !e.noDisplay);
            if (entries.length === 0) return Qt.exit(3);
            root.appName = entries[0].name;
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
            if (!Visual.findText(root.target.content, "#")) {
                console.error("launcher command: missing # icon");
                return Qt.exit(1);
            }
            root.center.store.dispatch({ type: "LauncherQuery", text: root.appName });
            back.start();
        }
    }
    Timer {
        id: back
        interval: 300
        onTriggered: {
            if (!Visual.findText(root.target.content, root.appName) || Visual.findText(root.target.content, "Wallpaper")) {
                console.error("launcher return: app result missing");
                return Qt.exit(1);
            }
            console.log("launcher return: app result shown");
            Qt.exit(0);
        }
    }
}
