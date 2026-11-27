import QtQuick
import QtTest
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property int cpuTicks: 100
    property var target: null

    FileView {
        id: cpuFixture
        path: Quickshell.env("NOTCH_SYSINFO_STAT")
    }

    Timer {
        id: fixtureUpdates
        interval: 500
        repeat: true
        running: true
        onTriggered: root.writeCpuSample()
    }

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
            root.target.resourceStats.setControlCenterOpen("monitor-b", true);
        }
    }

    function writeCpuSample() {
        cpuTicks += 10;
        cpuFixture.setText(`cpu ${cpuTicks} 0 0 100 0 0 0 0 0 0\n`);
    }

    TestCase {
        name: "ControlCenterResourcePollingLifecycle"
        when: root.target !== null

        function test_other_monitor_keeps_polling_and_last_close_stops() {
            wait(2300);
            if (root.target.resourceStats.cpuStatus !== "available") {
                console.error("resource polling: CPU did not sample while both monitors were open");
                return Qt.exit(1);
            }

            root.target.open = false;
            fixtureUpdates.running = false;
            cpuFixture.setText("not a cpu stat\n");
            cpuFixture.waitForJob();
            wait(2300);
            if (root.target.resourceStats.cpuStatus !== "invalid") {
                console.error("resource polling: remaining monitor did not read the changed CPU source");
                return Qt.exit(1);
            }

            root.writeCpuSample();
            root.writeCpuSample();
            cpuFixture.waitForJob();
            fixtureUpdates.running = true;
            wait(4300);
            if (root.target.resourceStats.cpuStatus !== "available") {
                console.error("resource polling: remaining monitor did not recover valid CPU telemetry");
                return Qt.exit(1);
            }

            root.target.resourceStats.setControlCenterOpen("monitor-b", false);
            fixtureUpdates.running = false;
            cpuFixture.setText("not a cpu stat\n");
            cpuFixture.waitForJob();
            wait(2300);
            if (root.target.resourceStats.cpuStatus !== "available") {
                console.error("resource polling: CPU changed after the last monitor closed");
                return Qt.exit(1);
            }
            Qt.exit(0);
        }
    }
}
