pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/theme.mjs" as ThemeLogic

// The theme mode and the matugen pipeline. The notch's own theme.json wins;
// the old shell's file is imported once when the notch has none, and is only
// read. Dynamic is permanent: every wallpaper commit and mode choice rebuilds
// the apps, an override only recolours its monitor.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string notchDir: stateHome + "/quickshell-notch"
    readonly property string oldDir: stateHome + "/quickshell"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string postHookPath: configHome + "/matugen/post-hook.sh"

    // scheme-* id; DEFAULT_MODE until a saved state says otherwise.
    property string mode: ThemeLogic.DEFAULT_MODE
    // true once the notch state on disk holds the current mode.
    property bool saved: false
    // true once the app pipeline and the queued monitor palettes are done.
    property bool applied: true
    property var palettes: ({})
    // One dry-run palette per scheme mode for the launcher previews, keyed by
    // screen so each monitor previews against its own wallpaper.
    property var previews: ({})

    property bool appDone: true
    property bool appBusy: false
    // The single app run still waiting: a newer commit replaces it, so the
    // last choice wins instead of being dropped.
    property var appNext: null
    property bool paletteBusy: false
    property var paletteQueue: []

    property bool previewBusy: false
    property var previewQueue: []
    property var previewPaths: ({})

    function previewFor(screen: string, mode: string): var {
        const own = previews[screen];
        return own ? (own[mode] ?? null) : null;
    }

    // Nine dry-runs against the monitor's current wallpaper, queued one at a
    // time so opening the view never spawns them in parallel. Repeated opens
    // with the same wallpaper reuse the cache.
    function generatePreviews(screen: string) {
        if (Flags.smoke)
            return;
        const path = Wallpapers.pathFor(screen);
        if (!path)
            return;
        if (previewPaths[screen] === path && previewFor(screen, ThemeLogic.MODES[0]))
            return;
        const paths = Object.assign({}, previewPaths);
        paths[screen] = path;
        previewPaths = paths;
        const jobs = [];
        for (const mode of ThemeLogic.MODES)
            jobs.push({
                screen: screen,
                mode: mode,
                path: path
            });
        previewQueue = previewQueue.filter(job => job.screen !== screen).concat(jobs);
        startPreview();
    }

    function startPreview() {
        if (previewBusy || previewQueue.length === 0)
            return;
        const job = previewQueue[0];
        previewQueue = previewQueue.slice(1);
        previewBusy = true;
        previewProc.pendingScreen = job.screen;
        previewProc.pendingMode = job.mode;
        previewProc.pending = true;
        previewProc.didStart = false;
        previewProc.command = ThemeLogic.dryArgs(job.path, job.mode);
        previewProc.running = true;
    }

    // Colours.paletteFor(screen) reads these; a screen without an entry
    // follows the global colors.json palette.
    function paletteFor(screen: string): var {
        return palettes[screen] ?? null;
    }

    function readText(path: string): var {
        reader.path = path;
        reader.reload();
        reader.waitForJob();
        return reader.loaded ? reader.text() : null;
    }

    function load() {
        const notch = readText(notchDir + "/theme.json");
        if (notch !== null) {
            mode = ThemeLogic.themeState(notch, null).mode;
            saved = true;
            return;
        }
        mode = ThemeLogic.themeState(null, readText(oldDir + "/theme.json")).mode;
        persist();
    }

    function persist() {
        saved = false;
        mkdir.running = true;
    }

    // Called by the theme view; an unknown id is ignored so a stale probe or
    // a corrupted state cannot start a matugen run with bogus args.
    function select(nextMode: string) {
        if (ThemeLogic.MODES.indexOf(nextMode) === -1)
            return;
        mode = nextMode;
        persist();
        apply(ThemeLogic.commitJobs({
            kind: "mode",
            wallpaper: Wallpapers.fallback,
            perScreen: Wallpapers.perScreen
        }));
    }

    // Called by Wallpapers.commit once its state holds the new path.
    function commitWallpaper(shared: bool, screen: string, path: string) {
        // A shared commit clears every override, so their palettes are stale.
        if (shared)
            palettes = ({});
        apply(ThemeLogic.commitJobs({
            kind: "wallpaper",
            shared: shared,
            screen: screen,
            path: path,
            perScreen: Wallpapers.perScreen
        }));
    }

    // Colours.paletteFor(screen) prefers these over the global colors.json.
    onPalettesChanged: Colours.overrides = palettes

    function apply(jobs: var) {
        if (Flags.smoke)
            return;
        applied = false;
        // An empty path means there is nothing to theme yet: the run is
        // skipped instead of spawning matugen with no image.
        if (jobs.app)
            runApp(jobs.app);
        appDone = !appBusy && appNext === null;
        paletteQueue = paletteQueue.concat(jobs.palettes);
        startPalette();
        checkApplied();
    }

    function checkApplied() {
        applied = appDone && !paletteBusy && paletteQueue.length === 0;
    }

    function runApp(path: string) {
        if (!path)
            return;
        appNext = {
            path: path
        };
        if (appBusy)
            return;
        startApp();
    }

    function startApp() {
        const job = appNext;
        if (!job) {
            appDone = true;
            checkApplied();
            return;
        }
        appNext = null;
        appBusy = true;
        appProc.pending = true;
        appProc.didStart = false;
        appProc.command = ThemeLogic.appArgs(job.path, root.mode);
        appProc.running = true;
    }

    // The app pipeline ends after matugen and its post-hook; a queued choice
    // starts next, otherwise the pipeline is done.
    function appFinished() {
        appBusy = false;
        if (appNext) {
            startApp();
            return;
        }
        appDone = true;
        checkApplied();
    }

    function startPalette() {
        while (!paletteBusy && paletteQueue.length !== 0) {
            const job = paletteQueue[0];
            paletteQueue = paletteQueue.slice(1);
            // A monitor without a usable path has nothing to dry-run.
            if (!job.path)
                continue;
            paletteBusy = true;
            paletteProc.pendingScreen = job.screen;
            paletteProc.pending = true;
            paletteProc.didStart = false;
            paletteProc.command = ThemeLogic.dryArgs(job.path, root.mode);
            paletteProc.running = true;
            return;
        }
        checkApplied();
    }

    // A dry-run that never started (no matugen on PATH) still frees its slot.
    function paletteFailed(reason: string) {
        console.warn("Theme: " + reason);
        paletteBusy = false;
        startPalette();
    }

    function previewFailed(reason: string) {
        console.warn("Theme: " + reason);
        previewBusy = false;
        startPreview();
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
                return console.warn("Theme: cannot create " + root.notchDir);
            writer.setText(JSON.stringify({
                mode: root.mode
            }));
        }
    }

    FileView {
        id: writer

        path: root.notchDir + "/theme.json"
        blockLoading: true
        printErrors: false
        onSaved: root.saved = true
        onSaveFailed: console.warn("Theme: cannot save " + path)
    }

    Process {
        id: appProc

        // A binary that cannot start never emits `exited`: `onStarted` stays
        // false and `running` drops back, which is the only failure signal.
        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                console.warn("Theme: can't run matugen");
                root.appFinished();
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0) {
                console.warn("Theme: matugen exited with " + code);
                root.appFinished();
                return;
            }
            postHook.pending = true;
            postHook.didStart = false;
            postHook.running = true;
        }
    }

    Process {
        id: postHook

        command: [root.postHookPath, "dark"]
        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                console.warn("Theme: can't run the matugen post-hook");
                root.appFinished();
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0)
                console.warn("Theme: post-hook exited with " + code);
            root.appFinished();
        }
    }

    Process {
        id: paletteProc

        property string pendingScreen: ""
        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                root.paletteFailed("can't run matugen for " + pendingScreen);
            }
        }

        stdout: StdioCollector {
            id: paletteOut

            onStreamFinished: {
                if (!paletteProc.pending)
                    return;
                paletteProc.pending = false;
                const palette = ThemeLogic.parseDryPalette(paletteOut.text);
                if (palette) {
                    const next = Object.assign({}, root.palettes);
                    next[paletteProc.pendingScreen] = palette;
                    root.palettes = next;
                } else {
                    console.warn("Theme: no palette for " + paletteProc.pendingScreen);
                }
                root.paletteBusy = false;
                root.startPalette();
            }
        }
    }

    Process {
        id: previewProc

        property string pendingScreen: ""
        property string pendingMode: ""
        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                root.previewFailed("can't preview " + pendingMode);
            }
        }

        stdout: StdioCollector {
            id: previewOut

            onStreamFinished: {
                if (!previewProc.pending)
                    return;
                previewProc.pending = false;
                const palette = ThemeLogic.parseDryPalette(previewOut.text);
                if (palette) {
                    const screen = previewProc.pendingScreen;
                    const current = root.previews[screen] ?? ({});
                    const own = Object.assign({}, current);
                    own[previewProc.pendingMode] = palette;
                    const next = Object.assign({}, root.previews);
                    next[screen] = own;
                    root.previews = next;
                }
                root.previewBusy = false;
                root.startPreview();
            }
        }
    }
}
