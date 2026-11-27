import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root
    property var target: null

    Timer {
        interval: 400
        running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            root.target = c.createObject(null, {
                screen: Quickshell.screens[0],
                open: false
            });
        }
    }

    TestCase {
        name: "ControlCenterResourcePolling"
        when: root.target !== null

        function test_resource_polling_starts_when_open() {
            wait(2500);
            if (root.target.resourceStats.cpuStatus !== "measuring") {
                console.error("resource polling: CPU was sampled while every control center was closed");
                return Qt.exit(1);
            }
            root.target.open = true;
            wait(2500);
            if (root.target.resourceStats.cpuStatus !== "available") {
                console.error("resource polling: CPU did not update after the control center opened");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
