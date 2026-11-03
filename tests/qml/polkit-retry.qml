import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var answers: []
    property var surface: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property QtObject flow: QtObject {
        property string message: "Authentication required"
        property bool isResponseRequired: true
        property string supplementaryMessage: ""
        property bool supplementaryIsError: false

        function submit(value) {
            root.answers.push(value);
            isResponseRequired = false;
        }
    }

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
        name: "PolkitRetry"
        when: true

        function test_retry() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "PolkitRequest",
                flowId: root.flow,
                monitor: screen.name
            });
            wait(600);

            let input = root.field(root.surface.content);
            let button = Visual.findNamed(root.surface.content, "polkitAcceptButton");
            if (!input || !button)
                return Qt.exit(2);
            input.insert(0, "first");
            mouseClick(button, button.width / 2, button.height / 2);
            wait(100);
            if (root.answers.length !== 1 || root.answers[0] !== "first" || input.text !== "") {
                console.error("polkit retry: first response not sent or input not cleared");
                return Qt.exit(1);
            }

            root.flow.supplementaryMessage = "Authentication failed";
            root.flow.supplementaryIsError = true;
            root.flow.isResponseRequired = true;
            wait(300);

            input = root.field(root.surface.content);
            button = Visual.findNamed(root.surface.content, "polkitAcceptButton");
            if (!input || !button || !Visual.findText(root.surface.content, "Authentication failed")) {
                console.error("polkit retry: retry prompt or failure message missing");
                return Qt.exit(1);
            }
            input.insert(0, "second");
            mouseClick(button, button.width / 2, button.height / 2);
            wait(100);
            if (root.answers.length !== 2 || root.answers[1] !== "second") {
                console.error("polkit retry: second response not sent");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
