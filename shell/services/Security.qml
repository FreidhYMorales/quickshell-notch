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
    readonly property string notchDir: stateHome + "/quickshell-notch"
    // The switch as set from the view this session; null until then.
    property var chosen: null
    readonly property bool fingerprintEnabled: chosen !== null ? chosen : LockSecurity.fingerprintEnabled(notchState.loaded ? notchState.text() : null, oldState.loaded ? oldState.text() : null)

    // Saved to the notch state only; the old shell's file is never written.
    function setFingerprintEnabled(on: bool) {
        chosen = on;
        mkdir.running = true;
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.notchDir]
        onExited: code => {
            if (code !== 0)
                return console.warn("Security: cannot create " + root.notchDir);
            notchState.setText(LockSecurity.serialiseSecurity(root.chosen));
        }
    }

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    property var enrolled: []

    property bool enrolling: false
    property string enrollingFinger: ""
    property int enrollTouches: 0
    // A key of Strings.enrollHints.
    property string enrollHint: ""

    // Only the ten fprintd finger names reach fprintd-enroll, as one argument.
    function startEnroll(finger: string) {
        if (enrolling || Fingerprint.freeFingers(enrolled).indexOf(finger) === -1)
            return;
        enrollingFinger = finger;
        enrollTouches = 0;
        enrollHint = "start";
        enrolling = true;
        enroll.command = ["fprintd-enroll", "-f", finger, root.userName];
        enroll.running = true;
    }

    // Stopping fprintd-enroll leaves at worst an incomplete enrollment.
    function cancelEnroll() {
        if (!enrolling)
            return;
        enroll.running = false;
        enrolling = false;
        refresh();
    }

    // fprintd-delete -f removes that one finger, not every registered one.
    function removeFinger(finger: string) {
        if (enrolled.indexOf(finger) === -1)
            return;
        remove.command = ["fprintd-delete", root.userName, "-f", finger];
        remove.running = true;
    }

    Process {
        id: remove
        onExited: root.refresh()
    }

    Process {
        id: enroll
        stdout: SplitParser {
            onRead: line => {
                const result = Fingerprint.enrollResult(line);
                if (result === null)
                    return;
                if (result.touch)
                    root.enrollTouches++;
                if (result.hint !== "")
                    root.enrollHint = result.hint;
                if (result.end !== "") {
                    root.enrolling = false;
                    root.refresh();
                }
            }
        }
    }

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
        path: root.notchDir + "/security.json"
        blockLoading: true
        printErrors: false
        onSaveFailed: console.warn("Security: cannot save " + path)
    }

    FileView {
        id: oldState
        path: root.stateHome + "/quickshell/security.json"
        blockLoading: true
        printErrors: false
    }
}
