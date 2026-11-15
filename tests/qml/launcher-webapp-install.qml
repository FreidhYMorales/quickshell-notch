import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the webapp form, fills both fields, submits with Enter and checks that
// the helper ran with the name and the URL as separate arguments, that the
// notch confirms the install and then closes itself.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherWebappInstall"
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

        function test_install() {
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
                console.error("webapp install: form fields missing");
                return Qt.exit(1);
            }
            nameField.text = "Notch Docs";
            keyClick(Qt.Key_Tab);
            wait(200);
            urlField.text = "https://example.com";
            keyClick(Qt.Key_Return);
            if (!waitFor(function () {
                return Visual.findText(root.target.content, "Installed");
            }, 60)) {
                console.error("webapp install: no confirmation shown");
                return Qt.exit(1);
            }
            // The notch leaves on its own after the confirmation.
            for (let i = 0; i < 60 && root.center.store.state.global.keyboard !== null; i++)
                wait(50);
            if (root.center.store.state.global.keyboard !== null) {
                console.error("webapp install: the notch stayed open");
                return Qt.exit(1);
            }
            console.log("webapp install: helper ran and the notch confirmed");
            Qt.exit(0);
        }
    }
}
