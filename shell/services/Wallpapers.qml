pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import "../logic/wallpaperPicker.mjs" as WallpaperPicker
import "../config"
import "../logic/wallpaperState.mjs" as WallpaperState
import "../logic/wallpaperSave.mjs" as WallpaperSave

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
    property var saveQueue: WallpaperSave.initialSaveQueue()
    readonly property string directory: Quickshell.env("QS_WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpaper")
    property var entries: []
    property var preview: null
    property var selection: null
    property bool applyToAll: false
    property string selectionMonitor: ""

    // On-demand, shared still-frame cache. One ffmpeg job at a time.
    readonly property string thumbnailDir: notchDir + "/thumbnails"
    property var thumbnailReady: ({})
    property var thumbnailRequested: ({})
    property var thumbnailQueue: []
    property string thumbnailWorking: ""
    property int thumbnailSerial: 0
    property string thumbnailOutputName: ""

    function thumbnailFor(path: string): string {
        if (!path || !/\.(mp4|webm|mkv|mov|avi|m4v)$/i.test(path))
            return "";
        if (thumbnailReady[path])
            return "file://" + thumbnailDir + "/" + thumbnailReady[path];
        requestThumbnail(path);
        return "";
    }

    function requestThumbnail(path: string) {
        if (!path || thumbnailRequested[path])
            return;
        const requested = Object.assign({}, thumbnailRequested);
        requested[path] = true;
        thumbnailRequested = requested;
        thumbnailQueue = thumbnailQueue.concat([path]);
        if (!thumbnailWorking && !thumbnailFolder.running)
            thumbnailFolder.running = true;
    }

    function startThumbnailJob() {
        if (thumbnailWorking || thumbnailQueue.length === 0)
            return;
        const path = thumbnailQueue[0];
        thumbnailQueue = thumbnailQueue.slice(1);
        thumbnailWorking = path;
        thumbnailSerial += 1;
        const name = "frame-" + thumbnailSerial + ".jpg";
        thumbnailOutputName = name;
        thumbnailExtractor.command = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
            "-y", "-i", path, "-frames:v", "1",
            "-q:v", "2", thumbnailDir + "/" + name];
        thumbnailExtractor.running = true;
    }

    Process {
        id: thumbnailFolder
        command: ["mkdir", "-p", root.thumbnailDir]
        onExited: code => {
            if (code === 0)
                root.startThumbnailJob();
            else
                console.warn("Wallpapers: cannot create thumbnail directory");
        }
    }

    Process {
        id: thumbnailExtractor
        property string extractingPath: ""
        onRunningChanged: {
            if (running)
                extractingPath = root.thumbnailWorking;
        }
        onExited: code => {
            const path = extractingPath;
            if (code === 0) {
                const ready = Object.assign({}, root.thumbnailReady);
                ready[path] = root.thumbnailOutputName;
                root.thumbnailReady = ready;
            } else {
                console.warn("Wallpapers: cannot extract frame from " + path + " (is ffmpeg installed?)");
            }
            root.thumbnailWorking = "";
            root.startThumbnailJob();
        }
    }

    function setApplyToAll(enabled: bool) {
        applyToAll = enabled;
        if (selection && selection.index >= 0)
            preview = {
                screen: applyToAll ? "" : selectionMonitor,
                path: selection.preview
            };
    }

    function refreshCatalog() {
        const paths = [];
        for (let i = 0; i < files.count; i++)
            paths.push(decodeURIComponent(files.get(i, "filePath").toString().replace("file://", "")));
        entries = WallpaperPicker.catalogEntries(paths);
        if (selection) {
            selection = WallpaperPicker.refreshPreview(selection, entries);
            preview = selection.index < 0 ? null : {
                screen: applyToAll ? "" : (preview?.screen ?? ""),
                path: selection.preview
            };
        }
    }

    function begin(screen: string) {
        selectionMonitor = screen;
        selection = WallpaperPicker.beginPreview(entries, WallpaperState.wallpaperFor(perScreen, fallback, screen));
        preview = selection.index < 0 ? null : {
            screen: applyToAll ? "" : screen,
            path: selection.preview
        };
    }

    function move(step: int, screen: string) {
        if (!selection)
            return;
        selection = WallpaperPicker.movePreview(selection, step);
        preview = selection.index < 0 ? null : {
            screen: applyToAll ? "" : screen,
            path: selection.preview
        };
    }

    function select(index: int, screen: string) {
        if (!selection || index < 0 || index >= selection.entries.length)
            return;
        selection = WallpaperPicker.movePreview(selection, index - selection.index);
        preview = {
            screen: applyToAll ? "" : screen,
            path: selection.preview
        };
    }

    function cancel() {
        preview = null;
        selection = null;
    }

    function commit(screen: string) {
        if (!selection || !selection.entries.length)
            return;
        const path = WallpaperPicker.commitPreview(selection);
        if (!path)
            return;
        const next = applyToAll ? WallpaperState.commitShared(path)
            : WallpaperState.commitFor(perScreen, fallback, screen, path);
        fallback = next.fallback;
        perScreen = next.perScreen;
        cancel();
        requestSave();
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
                perScreen = WallpaperState.normalizePerScreen(JSON.parse(json));
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
        requestSave();
    }

    function requestSave() {
        saveQueue = WallpaperSave.enqueueSave(saveQueue, fallback, perScreen);
        saved = false;
        startSave();
    }

    function startSave() {
        const next = WallpaperSave.startSave(saveQueue);
        if (next === saveQueue)
            return;
        saveQueue = next;
        mkdir.running = true;
    }

    function retrySave() {
        if (saveQueue.phase === "idle")
            startSave();
    }

    function failSave(reason: string) {
        console.warn("Wallpapers: save failed (" + reason + "); retry is available");
        saveQueue = WallpaperSave.failSave(saveQueue);
        saved = false;
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
            if (root.saveQueue.phase !== "mkdir")
                return;
            if (code !== 0) {
                root.failSave("mkdir");
                return;
            }
            const snapshot = root.saveQueue.active;
            root.saveQueue = WallpaperSave.advanceSave(root.saveQueue, "mkdir");
            defaultWriter.setText(snapshot.fallback);
        }
    }

    FileView {
        id: defaultWriter
        path: root.notchDir + "/wallpaper.txt"
        blockLoading: true
        printErrors: false
        onSaved: {
            if (root.saveQueue.phase !== "default")
                return;
            const snapshot = root.saveQueue.active;
            root.saveQueue = WallpaperSave.advanceSave(root.saveQueue, "default");
            screensWriter.setText(JSON.stringify(snapshot.perScreen));
        }
        onSaveFailed: root.failSave("default wallpaper")
    }

    FileView {
        id: screensWriter
        path: root.notchDir + "/wallpaper-screens.json"
        blockLoading: true
        printErrors: false
        onSaved: {
            if (root.saveQueue.phase !== "screens")
                return;
            root.saveQueue = WallpaperSave.advanceSave(root.saveQueue, "screens");
            root.saved = root.saveQueue.saved;
            root.startSave();
        }
        onSaveFailed: root.failSave("per-screen wallpapers")
    }
}
