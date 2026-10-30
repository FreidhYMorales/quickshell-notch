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

    // Detail views are the TUIs in kitty; the classes match the old config's
    // window rules.
    function openWifiTui() {
        Quickshell.execDetached(["kitty", "--class", "qs-wifi", "-e", "impala"]);
    }

    function openBtTui() {
        Quickshell.execDetached(["kitty", "--class", "qs-bluetooth", "-e", "bluetui"]);
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
