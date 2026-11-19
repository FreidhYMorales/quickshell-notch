pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../logic/lockSecurity.mjs" as LockSecurity
import "../logic/fingerprint.mjs" as Fingerprint

// Fingerprint unlock for the lock screen, kept in the notch's own state dir;
// until the notch saves it, the old shell's security.json decides (read only).
// The registered fingers are never cached: fprintd is asked each time.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property bool fingerprintEnabled: LockSecurity.fingerprintEnabled(notchState.loaded ? notchState.text() : null, oldState.loaded ? oldState.text() : null)

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    property var enrolled: []

    function refresh() {
        list.running = false;
        list.running = true;
    }

    Process {
        id: list
        command: ["fprintd-list", root.userName]
        stdout: StdioCollector {
            onStreamFinished: root.enrolled = Fingerprint.enrolledFingers(text)
        }
    }

    Component.onCompleted: refresh()

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
