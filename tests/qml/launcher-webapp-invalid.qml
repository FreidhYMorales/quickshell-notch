import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Submits a name the helper must not receive and then an empty URL: each names
// the field at fault, and the form never tells the helper to run.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherWebappInvalid"
        when: true

        function findCallback(items, name) {
            for (const item of items) {
                if (item.visible && typeof item[name] === "function")
                    return item;
                const found = item.children && item.children.length !== undefined ? findCallback(item.children, name) : null;
                if (found)
                    return found;
            }
            return null;
        }

        function waitFor(predicate, tries) {
            for (let i = 0; i < tries; i++) {
                const found = predicate();
                if (found)
                    return found;
                wait(50);
            }
            return predicate();
        }

        function test_invalid() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.target = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "LauncherToggle",
                monitor: screen.name
            });
            root.center.store.dispatch({
                type: "LauncherQuery",
                text: ">webapp"
            });
            wait(600);
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            const nameField = Visual.findNamed(root.target.content, "webapp-name");
            const urlField = Visual.findNamed(root.target.content, "webapp-url");
            if (!nameField || !urlField) {
                console.error("webapp invalid: form fields missing");
                return Qt.exit(1);
            }
            nameField.text = "My/App";
            urlField.text = "https://example.com";
            keyClick(Qt.Key_Return);
            if (!waitFor(function () {
                return Visual.findText(root.target.content, "Use a name without / or a leading dot");
            }, 40)) {
                console.error("webapp invalid: unsafe name not refused");
                return Qt.exit(1);
            }
            nameField.text = "Fine App";
            urlField.text = "";
            keyClick(Qt.Key_Return);
            if (!waitFor(function () {
                return Visual.findText(root.target.content, "URL is required");
            }, 40)) {
                console.error("webapp invalid: empty url not refused");
                return Qt.exit(1);
            }
            if (root.center.store.state.global.keyboard?.sub !== "webapp") {
                console.error("webapp invalid: the form closed on a refused submit");
                return Qt.exit(1);
            }
            console.log("webapp invalid: each fault is named and nothing ran");
            Qt.exit(0);
        }
    }
}
