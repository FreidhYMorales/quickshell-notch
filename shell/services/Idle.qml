pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../config"
import "../logic/idleState.mjs" as IdleState

// Idle timeouts (minutes), kept in the notch's own state dir. On first run
// the old shell's idle.json is imported once; its file is only read.
// Three idle watchers start the screensaver, then darken the lock and finally
// suspend; caffeine's inhibitor pauses all of them.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string notchDir: stateHome + "/quickshell-notch"
    readonly property string oldDir: stateHome + "/quickshell"

    property var timeouts: IdleState.parseIdle(null)
    // true once the notch state on disk holds the current timeouts.
    property bool saved: false
    readonly property var delays: IdleState.idleDelays(timeouts)
    // The screensaver wallpaper choice, written beside the times.
    property var choice: ({
            sameAsDesktop: true,
            path: ""
        })

    // A new time for one stage ("screensaver", "lock" or "suspend"). Clearing
    // `saved` until the file is written switches the watchers off and on
    // again, which re-arms them with the new timeout.
    function setMinutes(stage: string, minutes: int) {
        const next = Object.assign({}, timeouts);
        next[stage] = minutes;
        timeouts = next;
        saved = false;
        writer.setText(JSON.stringify(IdleState.serialiseIdle(timeouts, choice)));
    }

    // Enabled only once the timeouts are settled: a watcher created with the
    // default timeout and changed a moment later could never fire (old shell).
    IdleMonitor {
        enabled: !Flags.smoke && root.saved && root.delays.screensaverSec !== null
        timeout: root.delays.screensaverSec ?? 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Session.requestIdleLock();
        }
    }

    IdleMonitor {
        enabled: !Flags.smoke && root.saved && root.delays.lockSec !== null
        timeout: root.delays.lockSec ?? 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Session.beginBlack();
        }
    }

    IdleMonitor {
        enabled: !Flags.smoke && root.saved && root.delays.suspendSec !== null
        timeout: root.delays.suspendSec ?? 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Power.run("suspend");
        }
    }

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
