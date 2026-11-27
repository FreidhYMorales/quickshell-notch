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
                open: true
            });
        }
    }

    TestCase {
        name: "ControlCenterResourcePollingSmoke"
        when: root.target !== null

        function test_smoke_prevents_cpu_and_memory_polling() {
            wait(2500);
            if (root.target.resourceStats.cpuStatus !== "measuring" || root.target.resourceStats.memoryDetails !== null) {
                console.error("resource polling: smoke mode sampled CPU or memory");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
