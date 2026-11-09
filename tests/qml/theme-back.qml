import QtQuick
import QtTest
import Quickshell

// Opens the theme view, presses Escape and checks that the launcher is back
// on the command list with the saved mode untouched.
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
        name: "ThemeBack"
        when: true

        function test_back() {
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
            const launcher = root.findCallback(surface.content, "launch");
            if (!launcher)
                return Qt.exit(3);
            launcher.launch(0);
            wait(600);
            if (!root.findCallback(surface.content, "choose"))
                return Qt.exit(3);
            if (theme.mode !== "scheme-neutral") {
                console.error("theme back: wrong starting mode " + theme.mode);
                return Qt.exit(1);
            }
            keyClick(Qt.Key_Escape);
            wait(300);
            const keyboard = root.center.store.state.global.keyboard;
            if (!keyboard || keyboard.kind !== "launcher" || keyboard.sub !== null) {
                console.error("theme back: did not return to commands");
                return Qt.exit(1);
            }
            if (theme.mode !== "scheme-neutral") {
                console.error("theme back: mode changed to " + theme.mode);
                return Qt.exit(1);
            }
            console.log("theme back: commands with mode neutral");
            Qt.exit(0);
        }
    }
}
