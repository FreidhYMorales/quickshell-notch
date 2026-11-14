import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var surface
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "WebappFailure"
        when: true

        function test_failed_install() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            verify(component.status === Component.Ready && Quickshell.screens.length > 0, "surface or screen unavailable");
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, { screen: screen });
            root.center.store.dispatch({ type: "LauncherToggle", monitor: screen.name });
            root.center.store.dispatch({ type: "LauncherQuery", text: ">webapp" });
            root.center.store.dispatch({ type: "WebappOpen" });
            wait(1000);
            const name = Visual.findNamed(root.surface.content, "webapp-name");
            const url = Visual.findNamed(root.surface.content, "webapp-url");
            verify(name && url, "webapp form missing");
            name.text = "Notch Docs";
            url.text = "https://example.com";
            keyClick(Qt.Key_Return);
            let error = null;
            for (let i = 0; i < 60 && !error; i++) {
                wait(50);
                error = Visual.findText(root.surface.content, "Installation failed");
            }
            if (!error) {
                console.error("webapp failure: installation failure was not reported");
                return Qt.exit(1);
            }
            wait(1400);
            verify(Visual.findNamed(root.surface.content, "webapp-name"), "failure closed the form");
            verify(!Visual.findText(root.surface.content, "Installed"), "failure was reported as success");
            console.log("webapp failure: reported and form remains open");
            Qt.exit(0);
        }
    }
}
