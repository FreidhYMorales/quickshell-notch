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
            if (!Visual.findText(root.target.content, "󰸉")) { console.error("launcher glyphs: missing Wallpaper icon"); return Qt.exit(1); }
            console.log("launcher glyphs: Wallpaper shown");
            Qt.exit(0);
        }
    }
}
