import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the security view, picks Left thumb to enroll and prints the
// enrollment panel once the runner's fake fprintd-enroll reports one touch.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherSecurityEnroll"
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

        function test_enroll_shows_progress() {
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
            const thumb = Visual.findNamed(root.target.content, "security-add-left-thumb");
            if (!thumb) {
                console.error("security enroll: Left thumb is not offered");
                return Qt.exit(1);
            }
            mouseClick(thumb);
            wait(1000);
            const shown = [];
            for (const name of ["security-enroll-title", "security-enroll-hint", "security-enroll-touches"]) {
                const item = Visual.findNamed(root.target.content, name);
                shown.push(item ? item.text : "-");
            }
            console.log("security enroll: [" + shown.join(" | ") + "]");
            Qt.exit(0);
        }
    }
}
