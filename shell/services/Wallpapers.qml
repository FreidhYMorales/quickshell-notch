pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import "../logic/wallpaperPicker.mjs" as WallpaperPicker
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
    readonly property string directory: Quickshell.env("QS_WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpaper")
    property var entries: []
    property var preview: null
    property var selection: null

    function refreshCatalog() {
        const paths = [];
        for (let i = 0; i < files.count; i++)
            paths.push(decodeURIComponent(files.get(i, "filePath").toString().replace("file://", "")));
        entries = WallpaperPicker.catalogEntries(paths);
        if (selection) {
            selection = WallpaperPicker.refreshPreview(selection, entries);
            preview = selection.index < 0 ? null : {
                screen: preview?.screen ?? "",
                path: selection.preview
            };
        }
    }

    function begin(screen: string) {
        selection = WallpaperPicker.beginPreview(entries, WallpaperState.wallpaperFor(perScreen, fallback, screen));
        preview = selection.index < 0 ? null : {
            screen: screen,
            path: selection.preview
        };
    }

    function move(step: int, screen: string) {
        if (!selection)
            return;
        selection = WallpaperPicker.movePreview(selection, step);
        preview = selection.index < 0 ? null : {
            screen: screen,
            path: selection.preview
        };
    }

    function select(index: int, screen: string) {
        if (!selection || index < 0 || index >= selection.entries.length)
            return;
        selection = WallpaperPicker.movePreview(selection, index - selection.index);
        preview = {
            screen: screen,
            path: selection.preview
        };
    }

    function cancel() {
        preview = null;
        selection = null;
    }

    function commit(screen: string) {
        if (!selection)
            return;
        const path = WallpaperPicker.commitPreview(selection);
        if (!path)
            return;
        const next = WallpaperState.commitFor(perScreen, fallback, screen, path);
        fallback = next.fallback;
        perScreen = next.perScreen;
        cancel();
        saved = false;
        mkdir.running = true;
    }

    FolderListModel {
        id: files
        folder: "file://" + root.directory
        nameFilters: ["*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.webp", "*.WEBP", "*.bmp", "*.BMP", "*.mp4", "*.MP4", "*.webm", "*.WEBM", "*.mkv", "*.MKV", "*.mov", "*.MOV", "*.avi", "*.AVI", "*.m4v", "*.M4V"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready)
            root.refreshCatalog()
        onCountChanged: root.refreshCatalog()
    }

    function pathFor(screen: string): string {
        return WallpaperState.previewFor(perScreen, fallback, screen, preview) ?? "";
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
