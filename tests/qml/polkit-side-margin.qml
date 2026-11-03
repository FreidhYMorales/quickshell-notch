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

        function test_side_margin() {
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

            const message = Visual.findNamed(root.surface.content, "polkitMessage");
            const background = Visual.findNamed(root.surface.content, "polkitBackground");
            const field = Visual.findNamed(root.surface.content, "polkitField");
            const accept = Visual.findNamed(root.surface.content, "polkitAcceptButton");
            if (!message || !background) {
                console.error("polkit fingerprint: prompt missing");
                return Qt.exit(1);
            }
            if (field || accept) {
                console.error("polkit fingerprint: manual controls shown for an automatic request");
                return Qt.exit(1);
            }
            const side = message.mapToItem(background, 0, 0).x;
            if (side < 36 || background.width - side - message.width < 36) {
                console.error("polkit side margin: text is " + side + "px from the edge");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
