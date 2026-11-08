pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../logic/themeState.mjs" as ThemeState

// One global appearance choice. Preview is transient; only commit writes state.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string stateDir: stateHome + "/quickshell-notch"
    readonly property string statePath: stateDir + "/theme.json"

    property var committed: ThemeState.normalizeTheme(null)
    property var preview: null
    readonly property var current: preview ?? committed

    function begin() {
        preview = ThemeState.normalizeTheme(committed);
    }

    function setMode(mode: string) {
        if (preview)
            preview = ThemeState.selectTheme(preview, mode, null);
    }

    function setPreset(preset: string) {
        if (preview)
            preview = ThemeState.selectTheme(preview, null, preset);
    }

    function cancel() {
        preview = null;
    }

    function commit() {
        if (!preview)
            return;
        committed = ThemeState.normalizeTheme(preview);
        preview = null;
        // Write the complete JSON through argv, never through shell interpolation.
        const script = "import os,sys,tempfile; d=sys.argv[1]; os.makedirs(d,exist_ok=True); f=tempfile.NamedTemporaryFile(mode='w',dir=d,delete=False); f.write(sys.argv[2]); f.close(); os.replace(f.name,os.path.join(d,'theme.json'))";
        saver.command = ["python", "-c", script, stateDir, JSON.stringify(committed)];
        saver.running = true;
    }

    FileView {
        path: root.statePath
        onLoaded: root.committed = ThemeState.parseTheme(text())
        onLoadFailed: root.committed = ThemeState.normalizeTheme(null)
    }

    Process {
        id: saver
        onExited: code => {
            if (code !== 0)
                console.warn("Theme: could not save theme.json");
        }
    }
}
