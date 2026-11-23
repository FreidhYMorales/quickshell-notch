import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the security view, removes Right index and prints the registered
// fingers the view then shows (the runner's fakes keep them in a file).
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherSecurityRemove"
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

        function test_removed_finger_leaves_list() {
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
            const remove = Visual.findNamed(root.target.content, "security-print-right-index-finger");
            if (!remove) {
                console.error("security remove: no remove action for Right index");
                return Qt.exit(1);
            }
            mouseClick(remove);
            wait(1500);
            const thumb = Visual.findNamed(root.target.content, "security-print-left-thumb");
            const index = Visual.findNamed(root.target.content, "security-print-right-index-finger");
            console.log("security remove: left-thumb=" + (thumb && thumb.registered) + ", right-index=" + (index && index.registered));
            Qt.exit(0);
        }
    }
}
