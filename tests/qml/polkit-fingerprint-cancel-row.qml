import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root

    property var surface: null
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "PolkitFingerprint"
        when: true

        function test_fingerprint_cancel_beside_hint() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            root.surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "PolkitRequest",
                flowId: {
                    message: "Authentication is needed to run `/usr/bin/true' as the super user",
                    isResponseRequired: false,
                    supplementaryMessage: "Place your right index finger on the fingerprint reader",
                    supplementaryIsError: false
                },
                monitor: screen.name
            });
            wait(700);

            const cancel = Visual.findNamed(root.surface.content, "polkitCancelButton");
            const hint = Visual.findNamed(root.surface.content, "polkitError");
            if (!cancel || !hint) {
                console.error("polkit cancel beside hint: prompt parts missing");
                return Qt.exit(1);
            }
            const c = cancel.mapToItem(null, 0, 0);
            const h = hint.mapToItem(null, 0, 0);
            const sameRow = Math.abs((c.y + cancel.height / 2) - (h.y + hint.height / 2)) <= 2;
            if (!sameRow || c.x < h.x + hint.contentWidth) {
                console.error("polkit cancel beside hint: cancel is not to the right of the hint");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
