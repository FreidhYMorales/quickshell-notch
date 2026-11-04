pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/idleState.mjs" as IdleState

// Idle timeouts (minutes), kept in the notch's own state dir. On first run
// the old shell's idle.json is imported once; its file is only read.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string notchDir: stateHome + "/quickshell-notch"
    readonly property string oldDir: stateHome + "/quickshell"

    property var timeouts: IdleState.parseIdle(null)
    // true once the notch state on disk holds the current timeouts.
    property bool saved: false

    function readText(path: string): var {
        reader.path = path;
        reader.reload();
        reader.waitForJob();
        return reader.loaded ? reader.text() : null;
    }

    function load() {
        const notch = readText(notchDir + "/idle.json");
        if (notch !== null) {
            timeouts = IdleState.parseIdle(notch);
            saved = true;
            return;
        }
        timeouts = IdleState.parseIdle(readText(oldDir + "/idle.json"));
        mkdir.running = true;
    }

    Component.onCompleted: {
        if (!Flags.smoke)
            load();
    }

    FileView {
        id: reader

        blockLoading: true
        printErrors: false
    }

    Process {
        id: mkdir

        command: ["mkdir", "-p", root.notchDir]
        onExited: code => {
            if (code !== 0)
                return console.warn("Idle: cannot create " + root.notchDir);
            writer.setText(JSON.stringify({
                screensaverTimeoutMin: root.timeouts.screensaver,
                lockTimeoutMin: root.timeouts.lock,
                suspendTimeoutMin: root.timeouts.suspend
            }));
        }
    }

    FileView {
        id: writer

        path: root.notchDir + "/idle.json"
        blockLoading: true
        printErrors: false
        onSaved: root.saved = true
        onSaveFailed: console.warn("Idle: cannot save " + path)
    }
}
