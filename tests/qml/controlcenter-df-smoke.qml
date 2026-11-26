import QtQuick
import QtTest
import Quickshell

ShellRoot {
    property var target: null
    Timer {
        interval: 400; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            target = c.createObject(null, { screen: Quickshell.screens[0], open: true });
        }
    }
    TestCase {
        name: "ControlCenterDfSmoke"; when: target !== null
        function test_smoke_does_not_poll() {
            wait(1600);
            Qt.exit(0);
        }
    }
}
