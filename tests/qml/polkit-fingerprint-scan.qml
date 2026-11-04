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

        function test_fingerprint_scan() {
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

            const scan = Visual.findNamed(root.surface.content, "polkitFingerprintScan");
            if (!scan) {
                console.error("polkit fingerprint scan: scan line missing");
                return Qt.exit(1);
            }
            const before = scan.y;
            wait(300);
            if (scan.y === before) {
                console.error("polkit fingerprint scan: scan line does not move");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
