import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the launcher on the command list, activates Screensaver and checks
// that the view shows the three stored idle times (the runner stores 2/4/0).
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherScreensaverView"
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

        function test_view_shows_stored_times() {
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
                text: ">screensaver"
            });
            wait(600);
            if (!Visual.findText(root.target.content, "Screensaver")) {
                console.error("screensaver view: command missing from the list");
                return Qt.exit(1);
            }
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            for (const text of ["2 min", "4 min", "Off"]) {
                if (!Visual.findText(root.target.content, text)) {
                    console.error("screensaver view: missing " + text);
                    return Qt.exit(1);
                }
            }
            console.log("screensaver view: 2 min, 4 min and Off shown");
            Qt.exit(0);
        }
    }
}
