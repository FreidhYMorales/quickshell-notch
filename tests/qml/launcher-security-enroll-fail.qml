import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the security view, picks Left thumb to enroll and, once the runner's
// fake fprintd-enroll fails, prints the registered fingers and whether the
// enrollment panel is still shown.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "LauncherSecurityEnrollFail"
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

        function test_failed_enrollment_keeps_list() {
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
                console.error("security enroll fail: Left thumb is not offered");
                return Qt.exit(1);
            }
            mouseClick(thumb);
            wait(3000);
            const registered = Visual.findNamed(root.target.content, "security-registered");
            const shown = [];
            for (const label of ["Left thumb", "Right index"]) {
                if (registered && Visual.findText([registered], label))
                    shown.push(label);
            }
            const panel = Visual.findNamed(root.target.content, "security-enroll-title");
            console.log("security enroll fail: [" + shown.join(", ") + "], panel " + (panel ? "shown" : "hidden"));
            Qt.exit(0);
        }
    }
}
