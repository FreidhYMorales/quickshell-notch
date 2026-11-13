pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/keybinds.mjs" as KeybindsLogic

// Live keybind cheat sheet: Hyprland's own bind registry, so the view cannot
// drift from keybinds.lua.
Singleton {
    id: root

    property bool available: false
    property var rows: []

    // Called when the view opens; a no-op under smoke so probes never spawn
    // the real compositor query.
    function refresh() {
        if (Flags.smoke)
            return;
        bindsProc.running = true;
    }

    Process {
        id: bindsProc

        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            id: bindsOut

            onStreamFinished: {
                const parsed = KeybindsLogic.bindsFromJson(bindsOut.text);
                root.available = parsed.available;
                root.rows = parsed.rows;
            }
        }
    }
}
