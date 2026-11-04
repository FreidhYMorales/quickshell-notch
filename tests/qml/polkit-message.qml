import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "Authentication required" }, monitor: screen.name });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 500
        onTriggered: {
            if (!Visual.findText(root.target.content, "Authentication required")) {
                console.error("polkit view: request message not visible");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
