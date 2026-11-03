import QtQuick
import Quickshell
ShellRoot {
    id: root
    property var surface: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    function field(items) {
        for (const item of items) {
            if (item.visible && item.cursorPosition !== undefined) return item;
            const children = item.children, found = children && typeof children.length === "number" ? field(children) : null;
            if (found) return found;
        }
        return null;
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "First", isResponseRequired: true, cancelAuthenticationRequest: function() {} }, monitor: screen.name });
            check.start();
        }
    }
    Timer {
        id: check; interval: 500
        onTriggered: {
            const input = root.field(root.surface.content);
            if (!input) return Qt.exit(2);
            input.insert(0, "sample");
            root.center.store.dispatch({ type: "PolkitCancel" });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "Next", isResponseRequired: true }, monitor: Quickshell.screens[0].name });
            if (input.text !== "") { console.error("polkit clear: previous response remains"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
