import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the screensaver view. With NOTCH_PROBE_STEP=1 it checks that the
// picker is hidden while "Same as desktop wallpaper" is on, then turns the
// switch off. It prints whether the picker shows and the stored choice.
ShellRoot {
    id: root
    property var target: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var idle: Services.Idle }', root)

    TestCase {
        name: "LauncherScreensaverSwitch"
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

        function test_switch() {
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
                const same = Visual.findNamed(root.target.content, "screensaver-same");
                if (!same) {
                    console.error("screensaver switch: no Same as desktop wallpaper switch");
                    return Qt.exit(1);
                }
                if (Visual.findNamed(root.target.content, "screensaver-picker")) {
                    console.error("screensaver switch: picker shown while the switch is on");
                    return Qt.exit(1);
                }
                mouseClick(same);
                for (let i = 0; i < 30 && !idle.saved; i++)
                    wait(100);
                wait(300);
            }
            const picker = Visual.findNamed(root.target.content, "screensaver-picker");
            console.log("screensaver switch: picker " + (picker ? "shown" : "hidden") + ", same as desktop " + idle.choice.sameAsDesktop);
            Qt.exit(0);
        }
    }
}
