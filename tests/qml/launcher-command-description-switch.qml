import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    // The row of a command by its name, so adding a command never moves the
    // rows this probe selects.
    function indexOf(items, name) {
        for (const item of items) {
            if (item.visible && typeof item.launch === "function" && item.results)
                return item.results.findIndex(command => command.name === name);
            const found = item.children && item.children.length !== undefined ? indexOf(item.children, name) : -1;
            if (found !== -1)
                return found;
        }
        return -1;
    }

    function select(name) {
        const index = indexOf(root.target.content, name);
        if (index === -1) {
            console.error("launcher commands: " + name + " missing");
            return Qt.exit(1);
        }
        root.center.store.dispatch({ type: "LauncherSelect", index: index });
    }

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
            root.center.store.dispatch({ type: "LauncherQuery", text: ">" });
            first.start();
        }
    }
    Timer {
        id: first
        interval: 300
        onTriggered: {
            root.select("Theme");
            check.start();
        }
    }
    Timer {
        id: check
        interval: 800
        onTriggered: {
            if (!Visual.findText(root.target.content, "Choose the theme.")) {
                console.error("launcher commands: theme description missing");
                return Qt.exit(1);
            }
            root.select("Wallpaper");
            next.start();
        }
    }
    Timer {
        id: next
        interval: 300
        onTriggered: {
            if (!Visual.findText(root.target.content, "Choose the desktop wallpaper. Notch colours follow it.") || Visual.findText(root.target.content, "Choose the theme.")) {
                console.error("launcher commands: description did not follow selection");
                return Qt.exit(1);
            }
            console.log("launcher commands: description follows selection");
            Qt.exit(0);
        }
    }
}
