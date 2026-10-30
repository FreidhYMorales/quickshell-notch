pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/rfkill.mjs" as Rfkill

// WiFi radio (rfkill, root-less through the uaccess ACL on /dev/rfkill) and
// Bluetooth adapter power. Null means the radio is missing. `rfkill event`
// prints every device on start, then each change: no polling. Smoke runs
// never start it.
Singleton {
    id: root

    property var devices: ({})
    readonly property var wifi: Rfkill.wifiOn(devices)
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var bt: adapter ? adapter.enabled : null

    function toggleWifi() {
        if (wifi === null)
            return;
        Quickshell.execDetached(["rfkill", wifi ? "block" : "unblock", "wlan"]);
    }

    function toggleBt() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function openWifiTui() {
        Quickshell.execDetached(Commands.wifiTui);
    }

    function openBtTui() {
        Quickshell.execDetached(Commands.bluetoothTui);
    }

    function warnIfNoAdapter() {
        if (!adapter && !Flags.smoke)
            console.warn("Radios: no Bluetooth adapter; Bluetooth tile hidden");
    }

    onAdapterChanged: warnIfNoAdapter()

    // BlueZ fills the adapter asynchronously: check once after startup too.
    Timer {
        interval: Timings.startupGate
        running: true
        onTriggered: root.warnIfNoAdapter()
    }

    Process {
        command: ["rfkill", "event"]
        running: !Flags.smoke
        stdout: SplitParser {
            onRead: line => {
                const event = Rfkill.parseRfkillEvent(line);
                if (event)
                    root.devices = Rfkill.applyRfkillEvent(root.devices, event);
            }
        }
        onRunningChanged: {
            if (running || Flags.smoke)
                return;
            console.warn("Radios: rfkill event stopped; WiFi tile hidden");
            root.devices = {};
        }
    }
}
