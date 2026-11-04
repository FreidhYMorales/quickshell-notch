import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property int cancels: 0
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "PolkitPasswordEscape"
        when: true

        function test_cancel() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            const flow = {
                message: "Authentication is needed",
                isResponseRequired: true,
                supplementaryMessage: "Place your finger on the fingerprint reader",
                supplementaryIsError: false,
                cancelAuthenticationRequest: function () {
                    root.cancels += 1;
                }
            };
            root.center.store.dispatch({
                type: "PolkitRequest",
                flowId: flow,
                monitor: screen.name
            });
            wait(600);
            keyClick(Qt.Key_Escape);
            wait(100);
            if (root.cancels !== 1) {
                console.error("polkit password escape: password request not cancelled");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
