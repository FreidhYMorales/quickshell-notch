import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the security view from the command list and leaves it with Escape twice:
// the first returns to the commands, the second closes the launcher.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherSecurityBack"
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

        function test_escape_back() {
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
                text: ">security"
            });
            wait(600);
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            if (!Visual.findNamed(root.target.content, "security-hands")) {
                console.error("security back: view did not open");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Escape);
            wait(400);
            if (root.center.store.state.global.keyboard?.sub !== null) {
                console.error("security back: Escape did not return to the commands");
                return Qt.exit(1);
            }
            if (Visual.findNamed(root.target.content, "security-hands")) {
                console.error("security back: the view is still shown");
                return Qt.exit(1);
            }
            const query = root.center.store.state.global.keyboard?.query;
            if (query !== ">security") {
                console.error("security back: the command query became " + JSON.stringify(query));
                return Qt.exit(1);
            }
            if (!Visual.findText(root.target.content, "Security")) {
                console.error("security back: the command list is not back");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Escape);
            wait(400);
            if (root.center.store.state.global.keyboard !== null) {
                console.error("security back: second Escape did not close the launcher");
                return Qt.exit(1);
            }
            console.log("security back: Escape returns to the commands and closes");
            Qt.exit(0);
        }
    }
}
