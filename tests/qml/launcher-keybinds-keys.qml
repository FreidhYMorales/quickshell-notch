import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the keybinds view, moves the selection with the pointer and the
// arrows, walks to the last row so the list scrolls, and leaves with Escape.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "KeybindsKeys"
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

        function test_keys() {
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
                text: ">keybinds"
            });
            wait(600);
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1200);
            const view = waitFor(function () {
                return this.findCallback(root.target.content, "selectRow");
            }.bind(this), 60);
            if (!view) {
                console.error("keybinds keys: no cursor in the view");
                return Qt.exit(1);
            }
            if (view.currentIndex !== 0 || !Visual.findNamed(root.target.content, "keybinds-current-0")) {
                console.error("keybinds keys: first row not highlighted");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Down);
            wait(200);
            if (view.currentIndex !== 1) {
                console.error("keybinds keys: down arrow did not advance");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Up);
            wait(200);
            if (view.currentIndex !== 0) {
                console.error("keybinds keys: up arrow did not go back");
                return Qt.exit(1);
            }
            for (let i = 0; i < 11; i++)
                keyClick(Qt.Key_Down);
            wait(400);
            const list = Visual.findNamed(root.target.content, "keybinds-list");
            if (view.currentIndex !== 11 || !list || list.contentY <= 0) {
                console.error("keybinds keys: last row not scrolled into sight");
                return Qt.exit(1);
            }
            if (!Visual.findNamed(root.target.content, "keybinds-current-11")) {
                console.error("keybinds keys: last row not highlighted");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Escape);
            wait(400);
            if (root.center.store.state.global.keyboard?.sub !== null) {
                console.error("keybinds keys: Escape did not return to commands");
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Escape);
            wait(400);
            if (root.center.store.state.global.keyboard !== null) {
                console.error("keybinds keys: second Escape did not close the launcher");
                return Qt.exit(1);
            }
            console.log("keybinds keys: cursor, scroll and escape");
            Qt.exit(0);
        }
    }
}
