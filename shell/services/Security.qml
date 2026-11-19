pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../logic/lockSecurity.mjs" as LockSecurity

// Fingerprint unlock for the lock screen, kept in the notch's own state dir;
// until the notch saves it, the old shell's security.json decides (read only).
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property bool fingerprintEnabled: LockSecurity.fingerprintEnabled(notchState.loaded ? notchState.text() : null, oldState.loaded ? oldState.text() : null)

    FileView {
        id: notchState
        path: root.stateHome + "/quickshell-notch/security.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: oldState
        path: root.stateHome + "/quickshell/security.json"
        blockLoading: true
        printErrors: false
    }
}
