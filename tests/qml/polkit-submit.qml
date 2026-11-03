import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual
ShellRoot {
    id: root
    property string response: ""
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    function field(items) {
        for (const item of items) {
            if (item.visible && item.activeFocus && item.cursorPosition !== undefined) return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? field(children) : null;
            if (found) return found;
        }
        return null;
    }
    TestCase {
        name: "PolkitSubmit"
        when: true
        function test_submit() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, { screen: screen });
            const flow = { message: "Authentication required", isResponseRequired: true, submit: function(value) { root.response = value; } };
            root.center.store.dispatch({ type: "PolkitRequest", flowId: flow, monitor: screen.name });
            wait(600);
            const input = root.field(surface.content), button = Visual.findNamed(surface.content, "polkitAcceptButton");
            if (!input || !button) return Qt.exit(2);
            input.insert(0, "sample");
            mouseClick(button, button.width / 2, button.height / 2);
            wait(100);
            if (root.response !== "sample" || input.text !== "") {
                console.error("polkit submit: response not sent or input not cleared");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
