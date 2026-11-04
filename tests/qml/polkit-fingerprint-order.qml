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

        function test_fingerprint_order() {
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

            const glyph = Visual.findNamed(root.surface.content, "polkitFingerprintGlyph");
            const message = Visual.findNamed(root.surface.content, "polkitMessage");
            const hint = Visual.findNamed(root.surface.content, "polkitError");
            if (!glyph || !message || !hint) {
                console.error("polkit fingerprint order: prompt parts missing");
                return Qt.exit(1);
            }
            const glyphY = glyph.mapToItem(null, 0, 0).y;
            if (glyphY < message.mapToItem(null, 0, 0).y || glyphY > hint.mapToItem(null, 0, 0).y) {
                console.error("polkit fingerprint order: icon is not between the message and the hint");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
