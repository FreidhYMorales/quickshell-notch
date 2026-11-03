import QtQuick
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property var surface: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    Timer {
        interval: 500; running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "Authentication required", isResponseRequired: true, supplementaryMessage: "Authentication failed", supplementaryIsError: true }, monitor: screen.name });
            check.start();
        }
    }
    Timer {
        id: check; interval: 500
        onTriggered: {
            if (!Visual.findText(root.surface.content, "Authentication failed")) {
                console.error("polkit error: authentication failure not shown");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
