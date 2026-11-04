pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/wallpaperState.mjs" as WallpaperState

// Per-monitor wallpaper paths, kept in the notch's own state dir. On first
// run the old shell's state is imported once; its files are only read.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string notchDir: stateHome + "/quickshell-notch"
    readonly property string oldDir: stateHome + "/quickshell"

    property string fallback: ""
    property var perScreen: ({})
    // true once the notch state on disk holds the current values.
    property bool saved: false

    function pathFor(screen: string): string {
        return WallpaperState.wallpaperFor(perScreen, fallback, screen) ?? "";
    }

    function readText(path: string): string {
        reader.path = path;
        reader.reload();
        reader.waitForJob();
        return reader.loaded ? reader.text().trim() : "";
    }

    function readState(dir: string): var {
        const fallback = readText(dir + "/wallpaper.txt");
        const json = readText(dir + "/wallpaper-screens.json");
        let perScreen = {};
        if (json) {
            try {
                perScreen = JSON.parse(json) ?? {};
            } catch (e) {
                console.warn("Wallpapers: unreadable state in " + dir + ": " + e);
            }
        }
        return {
            fallback: fallback,
            perScreen: perScreen
        };
    }

    function load() {
        let state = readState(notchDir);
        if (!WallpaperState.shouldImport(state.perScreen, state.fallback)) {
            fallback = state.fallback;
            perScreen = state.perScreen;
            saved = true;
            return;
        }
        state = readState(oldDir);
        fallback = state.fallback;
        perScreen = state.perScreen;
        if (WallpaperState.shouldImport(perScreen, fallback)) {
            console.warn("Wallpapers: no saved wallpaper");
            return;
        }
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
                return console.warn("Wallpapers: cannot create " + root.notchDir);
            defaultWriter.setText(root.fallback);
        }
    }

    FileView {
        id: defaultWriter

        path: root.notchDir + "/wallpaper.txt"
        blockLoading: true
        printErrors: false
        onSaved: screensWriter.setText(JSON.stringify(root.perScreen))
        onSaveFailed: console.warn("Wallpapers: cannot save " + path)
    }

    FileView {
        id: screensWriter

        path: root.notchDir + "/wallpaper-screens.json"
        blockLoading: true
        printErrors: false
        onSaved: root.saved = true
        onSaveFailed: console.warn("Wallpapers: cannot save " + path)
    }
}
