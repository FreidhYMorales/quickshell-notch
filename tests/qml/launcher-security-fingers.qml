import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the security view and prints which fingerprint symbols are registered
// (the runner's fake fprintd-list decides which are registered).
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherSecurityFingers"
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

        function test_view_lists_registered_fingers() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready) {
                console.error("security fingers: CenterSurface status " + component.status + " " + component.errorString());
                return Qt.exit(2);
            }
            if (Quickshell.screens.length === 0)
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
            if (!Visual.findText(root.target.content, "Security")) {
                console.error("security view: command missing from the list");
                return Qt.exit(1);
            }
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            const hands = Visual.findNamed(root.target.content, "security-hands");
            if (!hands || !hands.visible) {
                console.error("security fingers: no hand diagram");
                return Qt.exit(1);
            }
            const shown = [];
            for (const name of ["left-thumb", "right-index-finger"]) {
                const print = Visual.findNamed(root.target.content, "security-print-" + name);
                if (print && print.registered)
                    shown.push(name);
            }
            console.log("security prints: [" + shown.join(", ") + "]");
            Qt.exit(0);
        }
    }
}
