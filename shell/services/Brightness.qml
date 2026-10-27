pragma Singleton

import Quickshell
import Quickshell.Io
import QtQml
import "../config"
import "../logic/brightness.mjs" as Logic

// Backlight percent. A udev watcher refreshes it when the level changes
// externally; reads and writes go through brightnessctl with argv only (never
// a shell). Sets are coalesced: one process in flight, the latest value
// pending. Without a backlight or the binary, `available` stays false.
Singleton {
    id: root

    property bool available: false
    property int percent: 0

    property int maxLevel: 0
    property bool dirty: false
    property var pending: null

    function set(p: real) {
        const argv = Logic.setArgs(p);
        if (!argv || !root.available || Flags.smoke)
            return;
        root.percent = Number(argv[2].slice(0, -1));
        if (setProc.running) {
            root.pending = argv;
            return;
        }
        setProc.command = argv;
        setProc.running = true;
    }

    function refresh() {
        if (getProc.running) {
            root.dirty = true;
            return;
        }
        getProc.running = true;
    }

    Component.onCompleted: {
        if (!Flags.smoke)
            maxProc.running = true;
    }

    Process {
        id: maxProc

        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: {
                const max = Logic.parseLevel(text);
                if (max === null || max <= 0) {
                    console.warn("Brightness: no usable backlight; OSD disabled");
                    return;
                }
                root.maxLevel = max;
                root.available = true;
                root.refresh();
            }
        }
    }

    Process {
        id: getProc

        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = Logic.percentOf(Logic.parseLevel(text), root.maxLevel);
                if (pct !== null)
                    root.percent = pct;
            }
        }
        onExited: {
            if (root.dirty) {
                root.dirty = false;
                running = true;
            }
        }
    }

    Process {
        id: setProc

        onExited: {
            if (root.pending) {
                command = root.pending;
                root.pending = null;
                running = true;
            }
        }
    }

    Process {
        id: watcher

        command: ["udevadm", "monitor", "--subsystem-match=backlight", "--udev"]
        running: root.available && !Flags.smoke
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("change") >= 0)
                    root.refresh();
            }
        }
        onExited: code => console.warn("Brightness: udev watcher exited (" + code + "); external changes are no longer tracked")
    }
}
