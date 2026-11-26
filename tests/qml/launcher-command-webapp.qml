import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher on the command list, activates Webapp and checks that the
// form appears with its two fields and the install action.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherCommandWebapp"
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

        function test_command_opens_form() {
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
            if (!Visual.findText(root.target.content, "Webapp")) {
                console.error("webapp view: command missing from the list");
                return Qt.exit(1);
            }
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            const name = Visual.findNamed(root.target.content, "webapp-name");
            if (!name) {
                console.error("webapp view: name field missing");
                return Qt.exit(1);
            }
            const url = Visual.findNamed(root.target.content, "webapp-url");
            if (!url) {
                console.error("webapp view: url field missing");
                return Qt.exit(1);
            }
            if (!Visual.findNamed(root.target.content, "webapp-name-placeholder")
                || !Visual.findNamed(root.target.content, "webapp-url-placeholder")) {
                console.error("webapp view: input placeholders missing");
                return Qt.exit(1);
            }
            if (!name.parent.color || !url.parent.color || name.parent.color.a <= 0 || url.parent.color.a <= 0) {
                console.error("webapp view: input background missing");
                return Qt.exit(1);
            }
            if (!Visual.findNamed(root.target.content, "webapp-install")) {
                console.error("webapp view: install action missing");
                return Qt.exit(1);
            }
            const installButton = Visual.findNamed(root.target.content, "webapp-install-button");
            const installSurface = Visual.findNamed(root.target.content, "webapp-install-surface");
            mouseMove(installButton, installButton.width / 2, installButton.height / 2);
            wait(150);
            if (!installButton.hovered) {
                console.error("webapp view: install action did not respond to hover");
                return Qt.exit(1);
            }
            if (installSurface.color.toString() !== installSurface.hoverColor.toString()) {
                console.error("webapp view: install hover color is not applied directly");
                return Qt.exit(1);
            }
            wait(600);
            if (!installButton.hovered) {
                console.error("webapp view: install hover did not remain active");
                return Qt.exit(1);
            }
            mouseMove(name, name.width / 2, name.height / 2);
            wait(200);
            if (installButton.hovered) {
                console.error("webapp view: install hover stayed active after leaving the button");
                return Qt.exit(1);
            }
            if (installSurface.color.toString() !== installSurface.restColor.toString()) {
                console.error("webapp view: install color did not return after leaving hover");
                return Qt.exit(1);
            }
            console.log("webapp view: name, url and install shown");
            Qt.exit(0);
        }
    }
}
