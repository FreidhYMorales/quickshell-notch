import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

ShellRoot { id: root; property var target: null
    Timer { interval: 500; running: true
        onTriggered: {
            const c = Qt.createComponent(Quickshell.env("NOTCH_CC_URL") + "/ControlCenterSurface.qml");
            if (c.status !== Component.Ready || Quickshell.screens.length === 0) return Qt.exit(2);
            root.target = c.createObject(null, { screen: Quickshell.screens[0], open: true, view: "resources", resourceStats: ({ networkActivity: null, networkActivityStatus: "measuring" }) });
        }
    }
    TestCase { name: "ControlCenterNetwork"; when: root.target !== null
        function test_network_rates_and_unavailable_states_are_visible() {
            let label = Visual.findText(root.target.content, "Receive rate");
            if (!label || label.parent.children[1].text !== "Measuring…") { console.error("resource view: receive rate is missing"); return Qt.exit(1); }
            root.target.resourceStats = Object.assign({}, root.target.resourceStats, { networkActivity: ({ receiveBytesPerSecond: 1536, transmitBytesPerSecond: 2048 }), networkActivityStatus: "available" });
            wait(100);
            if (!Visual.findText(root.target.content, "1.5 KiB/s") || !Visual.findText(root.target.content, "2.0 KiB/s")) { console.error("resource view: network rates are missing"); return Qt.exit(1); }
            root.target.resourceStats = Object.assign({}, root.target.resourceStats, { networkActivity: null, networkActivityStatus: "unavailable" });
            wait(100);
            label = Visual.findText(root.target.content, "Receive rate");
            if (!label || label.parent.children[1].text !== "Unavailable") { console.error("resource view: unavailable status is missing"); return Qt.exit(1); }
            Qt.exit(0);
        }
    }
}
