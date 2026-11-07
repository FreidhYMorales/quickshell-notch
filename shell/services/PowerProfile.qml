pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"
import "../logic/powerProfile.mjs" as Profile

// Active power profile from power-profiles-daemon: "performance", "balanced"
// or "power-saver". Null means the backend is missing, which hides the tile.
// Reads are short-lived and repeated when the panel opens; there is no
// long-lived watcher process.
Singleton {
    id: root

    property var current: null

    function refresh() {
        if (Flags.smoke || getProc.running)
            return;
        getProc.running = true;
    }

    function cycle() {
        if (root.current === null)
            return;
        root.set(Profile.cycleProfile(root.current));
    }

    function set(profile) {
        if (root.current === null || Flags.smoke)
            return;
        setProc.command = ["powerprofilesctl", "set", profile];
        setProc.running = true;
    }

    Process {
        id: getProc

        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: line => {
                const value = line.trim();
                if (value)
                    root.current = value;
            }
        }
        onExited: code => {
            if (code === 0)
                return;
            if (root.current === null)
                console.warn("PowerProfile: no power profiles backend; profile tile hidden");
            else
                console.warn("PowerProfile: could not read the profile (" + code + "); keeping " + root.current);
        }
    }

    Process {
        id: setProc

        // Re-read instead of trusting the requested value: the daemon may
        // clamp it, and an external change should not go unnoticed.
        onExited: code => {
            if (code !== 0)
                console.warn("PowerProfile: could not set the profile (" + code + ")");
            root.refresh();
        }
    }
}
