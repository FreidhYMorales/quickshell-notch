import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 400; running: true
        onTriggered: { const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml"); if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2); root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true }); }}
    TestCase { name: "ControlCenterNetworkPolling"; when: root.target !== null
        function test_network_activity_appears_after_two_samples() {
            wait(2800);
            const stats = root.target.resourceStats;
            for (const labelText of ["Receive rate", "Transmit rate"]) {
                const label = Visual.findText(root.target.content, labelText);
                if (!label || label.parent.children[1].text !== "0 B/s") { console.error("network polling: missing zero-rate sample", labelText); return Qt.exit(1); }
            }
            if (!stats.networkActivity || stats.networkActivityStatus !== "available" || stats.networkActivity.receiveBytesPerSecond !== 0 || stats.networkActivity.transmitBytesPerSecond !== 0) { console.error("network polling: service has no available sample"); return Qt.exit(1); }
            Qt.exit(0); }}
}
