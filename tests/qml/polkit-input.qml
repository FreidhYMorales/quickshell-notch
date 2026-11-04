import QtQuick
import Quickshell

ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    function focusedField(items) {
        for (const item of items) {
            if (item.visible && item.cursorPosition !== undefined && item.activeFocus)
                return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? focusedField(children) : null;
            if (found) return found;
        }
        return null;
    }
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "PolkitRequest", flowId: { message: "Authentication required", isResponseRequired: true, responseVisible: false }, monitor: screen.name });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 500
        onTriggered: {
            const field = root.focusedField(root.target.content);
            if (!field || field.echoMode !== TextInput.Password) {
                console.error("polkit input: no focused masked field");
                return Qt.exit(1);
            }
            field.insert(0, "sample");
            if (!field.text.startsWith("sample") || field.displayText.includes("sample")) return Qt.exit(1);
            Qt.exit(0);
        }
    }
}
