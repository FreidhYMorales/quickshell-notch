import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var surface
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "WebappReset"
        when: true

        function test_reopen() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">webapp" });
            root.center.store.dispatch({ type: "WebappOpen" });
            wait(600);
            let name = Visual.findNamed(root.surface.content, "webapp-name");
            let url = Visual.findNamed(root.surface.content, "webapp-url");
            if (!name || !url)
                return Qt.exit(2);
            name.text = "Stale App";
            url.text = "https://example.com";
            keyClick(Qt.Key_Escape);
            wait(400);
            if (root.center.store.state.global.keyboard?.sub !== null)
                return Qt.exit(2);
            root.center.store.dispatch({ type: "WebappOpen" });
            wait(600);
            name = Visual.findNamed(root.surface.content, "webapp-name");
            url = Visual.findNamed(root.surface.content, "webapp-url");
            if (!name || !url || name.text !== "" || url.text !== "") {
                console.error("webapp reset: reopened fields were not empty");
                return Qt.exit(1);
            }
            console.log("webapp reset: both fields empty after reopen");
            Qt.exit(0);
        }
    }
}
