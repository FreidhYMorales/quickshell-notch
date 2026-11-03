import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property bool cancelled: false
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)
    TestCase {
        name: "PolkitCancel"
        when: true
        function test_cancel() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, { screen: screen });
            const flow = { message: "Authentication required", isResponseRequired: true, cancelAuthenticationRequest: function() { root.cancelled = true; } };
            root.center.store.dispatch({ type: "PolkitRequest", flowId: flow, monitor: screen.name });
            wait(600);
            const button = Visual.findNamed(surface.content, "polkitCancelButton");
            if (!button) return Qt.exit(2);
            mouseClick(button, button.width / 2, button.height / 2);
            wait(100);
            if (!root.cancelled || root.center.store.viewFor(screen.name).mode === "polkit") {
                console.error("polkit cancel: request not cancelled and closed");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
