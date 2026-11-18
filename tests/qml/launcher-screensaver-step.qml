import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the screensaver view; with NOTCH_PROBE_STEP=1 it presses the
// screensaver "+" once. It then prints the screensaver value the view shows
// and the delay the idle chain uses.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var idle: Services.Idle }', root)

    TestCase {
        name: "LauncherScreensaverStep"
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

        function test_step() {
            const idle = root.services.idle;
            for (let i = 0; i < 50 && !idle.saved; i++)
                wait(100);
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
            const launcher = waitFor(function () {
                return this.findCallback(root.target.content, "launch");
            }.bind(this), 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(1000);
            if (Quickshell.env("NOTCH_PROBE_STEP") === "1") {
                const more = Visual.findNamed(root.target.content, "idle-screensaver-more");
                if (!more) {
                    console.error("screensaver step: no + for the screensaver time");
                    return Qt.exit(1);
                }
                mouseClick(more);
                for (let i = 0; i < 30 && !idle.saved; i++)
                    wait(100);
                wait(300);
            }
            const value = Visual.findNamed(root.target.content, "idle-screensaver-value");
            console.log("screensaver step: shows " + (value ? value.text : "nothing") + ", delay " + idle.delays.screensaverSec);
            Qt.exit(0);
        }
    }
}
