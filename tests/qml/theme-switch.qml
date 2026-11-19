import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the theme view from the launcher, flips the Light/Dark switch with Tab
// and back with a click, reading the variant and the switch label each time.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme }', root)

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

    TestCase {
        name: "ThemeSwitch"
        when: true

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
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "LauncherToggle",
                monitor: screen.name
            });
            root.center.store.dispatch({
                type: "LauncherQuery",
                text: ">theme"
            });
            wait(600);
            const launcher = waitFor(function () {
                return root.findCallback(surface.content, "launch");
            }, 60);
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(600);
            if (!waitFor(function () {
                return root.findCallback(surface.content, "choose");
            }, 60))
                return Qt.exit(3);
            // Let the view settle before it takes key events.
            wait(400);
            const label = () => {
                const item = Visual.findNamed(surface.content, "theme-variant-switch");
                return item ? item.text : "none";
            };
            const before = theme.variant + " " + label();
            keyClick(Qt.Key_Tab);
            waitFor(function () {
                return theme.saved && theme.applied;
            }, 200);
            wait(200);
            const tab = theme.variant + " " + label();
            const item = Visual.findNamed(surface.content, "theme-variant-switch");
            if (item)
                mouseClick(item);
            waitFor(function () {
                return theme.saved && theme.applied;
            }, 200);
            wait(200);
            const click = theme.variant + " " + label();
            console.log("theme switch: start " + before + ", tab " + tab + ", click " + click);
            Qt.exit(0);
        }
    }
}
