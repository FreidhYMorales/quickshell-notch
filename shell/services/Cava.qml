pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/visualizer.mjs" as Viz

// Runs `cava` only while `wanted` (set by the centre store when the media
// layer shows). Frames become `levels` (0..1 per bar). Never runs under
// Flags.smoke. A dead cava is restarted Limits.cavaRetries times per play
// session, then `available` turns false and the visualizer hides.
Singleton {
    id: root

    property bool wanted: false
    property bool available: true
    readonly property bool running: wanted && !Flags.smoke && available
    property var levels: zeros()

    readonly property string configPath: Quickshell.cachePath("cava.conf")
    readonly property string configText: Viz.cavaConfig({
        bars: Limits.cavaBars,
        framerate: Limits.cavaFps,
        maxRange: Limits.cavaMaxRange
    })

    property string written: ""
    property int retries: 0
    property bool cooling: false

    function zeros(): var {
        const out = [];
        for (let i = 0; i < Limits.cavaBars; i++)
            out.push(0);
        return out;
    }

    // Rewrites the config only when its text changed since the last save.
    function ensureConfig() {
        if (root.written !== root.configText)
            conf.setText(root.configText);
    }

    onRunningChanged: {
        if (running)
            ensureConfig();
        else
            levels = zeros();
    }

    // A new play session gets a fresh retry budget.
    onWantedChanged: {
        if (!wanted) {
            retries = 0;
            cooling = false;
            restart.stop();
            available = true;
        }
    }

    FileView {
        id: conf

        path: root.configPath
        printErrors: false
        onLoaded: {
            if (text() === root.configText)
                root.written = root.configText;
        }
        onSaved: root.written = root.configText
        onSaveFailed: {
            console.warn("Cava: cannot write " + root.configPath + "; visualizer disabled");
            root.available = false;
        }
    }

    Process {
        id: proc

        command: ["cava", "-p", root.configPath]
        running: root.running && root.written === root.configText && !root.cooling
        stdout: SplitParser {
            onRead: line => {
                const next = Viz.parseFrame(line, Limits.cavaBars, Limits.cavaMaxRange);
                if (next)
                    root.levels = next;
            }
        }
        // Fires for an exit and for a binary that cannot start (no `exited`
        // is emitted then); a stop that we asked for has root.running false.
        onRunningChanged: {
            if (running || !root.running || root.cooling)
                return;
            if (root.retries >= Limits.cavaRetries) {
                console.warn("Cava: stopped " + root.retries + " times; visualizer disabled");
                root.available = false;
                return;
            }
            root.retries++;
            root.cooling = true;
            restart.start();
        }
    }

    Timer {
        id: restart

        interval: Timings.cavaRestart
        onTriggered: root.cooling = false
    }
}
