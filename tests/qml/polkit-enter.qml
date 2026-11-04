import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root

    property var answers: []
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    function field(items) {
        for (const item of items) {
            if (item.visible && item.activeFocus && item.cursorPosition !== undefined)
                return item;
            const children = item.children;
            const found = children && typeof children.length === "number" ? field(children) : null;
            if (found)
                return found;
        }
        return null;
    }

    TestCase {
        name: "PolkitEnter"
        when: true

        function test_enter() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            const flow = {
                message: "Authentication required",
                isResponseRequired: true,
                submit: function (value) {
                    root.answers.push(value);
                }
            };
            root.center.store.dispatch({
                type: "PolkitRequest",
                flowId: flow,
                monitor: screen.name
            });
            wait(600);
            const input = root.field(surface.content);
            if (!input)
                return Qt.exit(2);
            input.insert(0, "secret");
            keyClick(Qt.Key_Return);
            wait(100);
            if (root.answers.length !== 1 || root.answers[0] !== "secret" || input.text !== "") {
                console.error("polkit enter: response not submitted or input not cleared");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
