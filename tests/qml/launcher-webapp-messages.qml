import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var surface
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "WebappMessages"
        when: true

        function test_messages() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">webapp" });
            root.center.store.dispatch({ type: "WebappOpen" });
            wait(1000);
            const name = Visual.findNamed(root.surface.content, "webapp-name");
            const url = Visual.findNamed(root.surface.content, "webapp-url");
            if (!name || !url)
                return Qt.exit(2);
            name.text = "";
            url.text = "https://example.com";
            keyClick(Qt.Key_Return);
            wait(200);
            if (!Visual.findText(root.surface.content, "Name is required")) {
                console.error("webapp messages: missing name error");
                return Qt.exit(1);
            }
            name.text = "Notch Docs";
            url.text = "ftp://example.com";
            keyClick(Qt.Key_Return);
            wait(200);
            if (!Visual.findText(root.surface.content, "Use an http or https URL")) {
                console.error("webapp messages: invalid URL error missing");
                return Qt.exit(1);
            }
            if (!Visual.findNamed(root.surface.content, "webapp-name"))
                return Qt.exit(1);
            console.log("webapp messages: missing name and invalid URL");
            Qt.exit(0);
        }
    }
}
