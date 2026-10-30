pragma Singleton

import Quickshell

// External programs the shell launches (argv arrays, no shell).
Singleton {
    // Control center detail views: TUIs in kitty. The classes match the old
    // config's window rules.
    readonly property var wifiTui: ["kitty", "--class", "qs-wifi", "-e", "impala"]
    readonly property var bluetoothTui: ["kitty", "--class", "qs-bluetooth", "-e", "bluetui"]
}
