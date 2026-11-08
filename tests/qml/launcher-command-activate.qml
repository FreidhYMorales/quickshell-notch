import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    function launcher(items) {
        for (const item of items) {
            if (item.visible && typeof item.launch === "function") return item;
            const found = item.children && launcher(item.children);
            if (found) return found;
        }
        return null;
    }
    Timer {
        interval: 2500; running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">theme" });
            activate.start();
        }
    }
    Timer {
        id: activate; interval: 800
        onTriggered: {
            const view = root.launcher(root.target.content);
            if (!view || !Visual.findText(root.target.content, "Theme")) return Qt.exit(2);
            view.launch(0);
            check.start();
        }
    }
    Timer {
        id: check; interval: 300
        onTriggered: {
            if (!Visual.findText(root.target.content, "Theme") || !Visual.findText(root.target.content, "Not available yet")) return Qt.exit(1);
            console.log("launcher commands: unavailable activation ignored");
            Qt.exit(0);
        }
    }
}
