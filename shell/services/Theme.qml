pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/theme.mjs" as ThemeLogic
import "../logic/wallpaperState.mjs" as WallpaperState

// The theme mode and the matugen pipeline. The notch's own theme.json wins;
// the old shell's file is imported once when the notch has none, and is only
// read. Dynamic is permanent: every wallpaper commit and mode choice rebuilds
// the apps, an override only recolours its monitor.
Singleton {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    readonly property string notchDir: stateHome + "/quickshell-notch"
    property string sddmDataDir: Quickshell.env("NOTCH_SDDM_DATA_DIR") || (notchDir + "/sddm")
    // Opt in only: deployment must provision this separate directory first.
    property string greetdDataDir: Quickshell.env("NOTCH_GREETD_DATA_DIR")
    readonly property string oldDir: stateHome + "/quickshell"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string postHookPath: configHome + "/matugen/post-hook.sh"

    // scheme-* id; DEFAULT_MODE until a saved state says otherwise.
    property string mode: ThemeLogic.DEFAULT_MODE
    // "light" or "dark": only the apps follow it, the notch stays dark.
    property string variant: "dark"
    // true once the notch state on disk holds the current mode.
    property bool saved: false
    // true once the app pipeline and the queued monitor palettes are done.
    property bool applied: true
    property var palettes: ({})
    // Dark dry-run palette of the shared wallpaper, only while the apps are
    // light: their colors.json then no longer fits the notch.
    property var sharedPalette: null
    // One dry-run palette per scheme mode for the launcher previews, keyed by
    // screen so each monitor previews against its own wallpaper.
    property var previews: ({})

    property bool appDone: true
    property bool appBusy: false
    property string appBackground: ""
    property string sddmWallpaper: ""
    property var sddmNext: null
    property bool sddmBusy: false
    property var greetdNext: null
    property bool greetdBusy: false
    // Idle notch width per monitor, reported by the centre surface. Published
    // with the greeter assets so the login surface compresses into the same
    // shape the session will show instead of a fixed preset.
    property var idleNotchWidths: ({})
    // The single app run still waiting: a newer commit replaces it, so the
    // last choice wins instead of being dropped.
    property var appNext: null
    property bool paletteBusy: false
    property var paletteQueue: []
    // Bumped when a shared commit invalidates the overrides still being
    // recoloured, so a dry-run that finishes late cannot write a stale palette.
    property int paletteEpoch: 0

    property bool previewBusy: false
    property var previewQueue: []
    property var previewPaths: ({})
    // Bumped by a wallpaper commit: previews computed from the old wallpaper
    // are dropped instead of being stored.
    property int previewEpoch: 0

    property var frameQueue: []
    property bool frameBusy: false
    property var frameJob: null
    // role -> video already extracted in this session.
    property var frames: ({})
    // Startup restored the saved per-monitor palettes once.
    property bool restored: false
    property bool loaded: false

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
        // Only a full set is a cache hit: a commit elsewhere may have dropped
        // the rest of this monitor's queued jobs.
        if (previewPaths[screen] === path && ThemeLogic.MODES.every(mode => previewFor(screen, mode)))
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
        const epoch = root.previewEpoch;
        previewProc.epoch = epoch;
        // A commit may land while the frame is still being extracted: by then
        // a newer job owns previewProc, so the stale callback does nothing.
        frameFor(job.path, "preview", path => {
            if (epoch !== root.previewEpoch)
                return;
            previewProc.pending = true;
            previewProc.didStart = false;
            previewProc.command = ThemeLogic.dryArgs(path, job.mode);
            previewProc.running = true;
        }, reason => {
            if (epoch === root.previewEpoch)
                root.previewFailed(reason);
        });
    }

    // --- video wallpapers ---------------------------------------------------
    // matugen only reads images: a video wallpaper is themed from the frame in
    // its middle, extracted once per role and video so no two jobs, and no
    // two videos, ever share a file.
    function framePath(role: string, path: string): string {
        return Quickshell.cachePath(Qt.md5(path) + "-theme-frame-" + role + ".png");
    }

    function frameFor(path: string, role: string, run: var, fail: var) {
        // One frame per role and video per session: the nine previews share it
        // instead of re-extracting the same still nine times.
        const output = framePath(role, path);
        if (frames[output]) {
            run(output);
            return;
        }
        if (!WallpaperState.needsThemeFrame(path)) {
            run(path);
            return;
        }
        frameQueue = frameQueue.concat([
            {
                path: path,
                role: role,
                output: output,
                run: run,
                fail: fail
            }
        ]);
        startFrame();
    }

    function startFrame() {
        if (frameBusy || frameQueue.length === 0)
            return;
        const next = frameQueue[0];
        frameQueue = frameQueue.slice(1);
        // Queued twice before the first landed: never rewrite a frame a
        // dry-run may be reading.
        if (frames[next.output]) {
            next.run(next.output);
            startFrame();
            return;
        }
        frameJob = next;
        frameBusy = true;
        probe.pending = true;
        probe.didStart = false;
        probe.command = ThemeLogic.probeArgs(frameJob.path);
        probe.running = true;
    }

    function frameFailed(reason: string) {
        const job = frameJob;
        frameJob = null;
        frameBusy = false;
        if (job)
            job.fail(reason);
        startFrame();
    }

    function frameReady() {
        const job = frameJob;
        frameJob = null;
        frameBusy = false;
        if (job) {
            const done = Object.assign({}, frames);
            done[job.output] = true;
            frames = done;
            job.run(job.output);
        }
        startFrame();
    }

    function readText(path: string): var {
        reader.path = path;
        reader.reload();
        reader.waitForJob();
        return reader.loaded ? reader.text() : null;
    }

    function load() {
        if (!greetdDataDir) {
            const target = readText(notchDir + "/greetd-target.txt");
            const path = target ? target.trim() : "";
            if (/^\/[^\r\n]*$/.test(path))
                greetdDataDir = path;
        }
        if (!Quickshell.env("NOTCH_SDDM_DATA_DIR")) {
            const target = readText(notchDir + "/sddm-target.txt");
            const path = target ? target.trim() : "";
            if (/^\/[^\r\n]*$/.test(path))
                sddmDataDir = path;
        }
        const sddmConfig = readText(sddmDataDir + "/theme.conf.user");
        const source = sddmConfig && sddmConfig.match(/^sourceWallpaper=file:\/\/(.*)$/m);
        if (source) {
            try {
                sddmWallpaper = decodeURIComponent(source[1]);
            } catch (_error) {
                console.warn("Theme: invalid SDDM wallpaper path");
            }
        }
        const notch = readText(notchDir + "/theme.json");
        const old = readText(oldDir + "/theme.json");
        variant = ThemeLogic.themeVariant(notch, old);
        if (notch !== null) {
            const stored = ThemeLogic.savedMode(notch);
            mode = stored ?? ThemeLogic.DEFAULT_MODE;
            // A broken file is replaced by the default instead of keeping it.
            if (stored === null)
                persist();
            else
                saved = true;
        } else {
            mode = ThemeLogic.themeState(null, old).mode;
            persist();
        }
        loaded = true;
        restorePalettes();
    }

    // Palettes are derived, never stored: a fresh start rebuilds them from the
    // saved wallpapers, once, without rerunning the apps.
    function restorePalettes() {
        if (restored || !loaded || Flags.smoke || !Wallpapers.saved)
            return;
        const jobs = [];
        for (const screen in Wallpapers.perScreen) {
            jobs.push({
                screen: screen,
                path: Wallpapers.perScreen[screen]
            });
        }
        // Light apps left a light colors.json: the shared notch palette is
        // rebuilt dark from the shared wallpaper.
        if (variant === "light" && Wallpapers.fallback)
            jobs.push({
                screen: "",
                path: Wallpapers.fallback
            });
        if (jobs.length === 0)
            return;
        restored = true;
        applied = false;
        paletteQueue = paletteQueue.concat(jobs);
        startPalette();
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

    // Called by the theme view's switch: only the apps are rethemed, from the
    // shared wallpaper; the notch palettes never depend on the variant.
    function setVariant(nextVariant: string) {
        if (nextVariant !== "light" && nextVariant !== "dark")
            return;
        variant = nextVariant;
        persist();
        apply({
            app: Wallpapers.fallback,
            palettes: []
        });
    }

    // Called by Wallpapers.commit once its state holds the new path.
    function commitWallpaper(shared: bool, screen: string, path: string) {
        sddmWallpaper = path;
        // A shared commit clears every override, so their palettes are stale:
        // the queue is dropped and a dry-run already running is abandoned.
        if (shared) {
            palettes = ({});
            paletteEpoch += 1;
            paletteQueue = [];
            cancelPalette();
        }
        // Either way the previews were computed from the old wallpaper.
        previewEpoch += 1;
        previewQueue = [];
        cancelPreview();
        const kept = {};
        for (const name in previews) {
            if (!shared && name !== screen)
                kept[name] = previews[name];
        }
        previews = kept;
        apply(ThemeLogic.commitJobs({
            kind: "wallpaper",
            shared: shared,
            screen: screen,
            path: path,
            perScreen: Wallpapers.perScreen
        }));
    }

    function cancelPalette() {
        paletteProc.pending = false;
        paletteProc.running = false;
        paletteBusy = false;
    }

    function cancelPreview() {
        previewProc.pending = false;
        previewProc.running = false;
        previewBusy = false;
    }

    // The greeter shows on one monitor and only needs one width: publish the
    // widest idle notch, which matches every monitor whose slot is not capped.
    function setIdleNotchWidth(monitor: string, width: int) {
        if (!monitor || width <= 0 || idleNotchWidths[monitor] === width)
            return;
        const next = Object.assign({}, idleNotchWidths);
        next[monitor] = width;
        idleNotchWidths = next;
    }

    function greeterNotchWidth(): int {
        let widest = 0;
        for (const name in idleNotchWidths)
            widest = Math.max(widest, idleNotchWidths[name]);
        return widest;
    }

    // Colours.paletteFor(screen) prefers these over the global colors.json.
    onPalettesChanged: Colours.overrides = palettes
    onSharedPaletteChanged: Colours.shared = sharedPalette

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
        // Light apps leave colors.json unfit for the notch: every app run
        // also dry-runs the same wallpaper dark for the shared notch palette.
        if (jobs.app && variant === "light")
            paletteQueue = paletteQueue.concat([
                {
                    screen: "",
                    path: jobs.app
                }
            ]);
        startPalette();
        checkApplied();
    }

    function checkApplied() {
        applied = appDone && !paletteBusy && paletteQueue.length === 0 && !sddmBusy && sddmNext === null && !greetdBusy && greetdNext === null;
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
        root.appBackground = job.path;
        const mode = root.mode;
        const variant = root.variant;
        frameFor(job.path, "app", path => {
            appProc.pending = true;
            appProc.didStart = false;
            appProc.variant = variant;
            appProc.command = ThemeLogic.appArgs(path, mode, variant);
            appProc.running = true;
        }, reason => {
            console.warn("Theme: " + reason);
            root.appFinished();
        });
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

    function stageSddm(path: string, palette: var) {
        if (!path || (sddmWallpaper && path !== sddmWallpaper))
            return;
        if (greetdDataDir && greetdDataDir !== sddmDataDir)
            stageGreetd(path, palette);
        else if (greetdDataDir)
            console.warn("Theme: greetd and SDDM staging directories must differ");
        sddmNext = {
            path: path,
            palette: palette
        };
        applied = false;
        if (sddmBusy)
            return;
        startSddm();
    }

    function stageGreetd(path: string, palette: var) {
        if (!greetdDataDir)
            return;
        // A queued app job must not read a later run's mutable colors.json.
        const snapshot = palette.charAt(0) === "{" ? palette : readText(palette);
        if (!snapshot) {
            console.warn("Theme: can't read greetd palette");
            greetdNext = null;
            return;
        }
        // Capture only the two tokens the publisher uses, rather than passing
        // the potentially large and mutable complete matugen output as argv.
        let colors;
        try {
            colors = JSON.parse(snapshot).colors;
            colors = {
                primary: {
                    hex: colors.primary.hex
                },
                on_surface: {
                    hex: colors.on_surface.hex
                }
            };
        } catch (_error) {
            console.warn("Theme: invalid greetd palette");
            greetdNext = null;
            return;
        }
        greetdNext = {
            path: path,
            palette: JSON.stringify({
                colors: colors
            })
        };
        applied = false;
        if (!greetdBusy)
            startGreetd();
    }

    function startGreetd() {
        const job = greetdNext;
        greetdNext = null;
        greetdBusy = true;
        greetdSync.pending = true;
        greetdSync.didStart = false;
        const command = ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/greetd-sync.py").toString().replace(/^file:\/\//, "")), job.path, job.palette, greetdDataDir];
        // Optional: the reader falls back to the theme preset when absent.
        const width = root.greeterNotchWidth();
        if (width > 0)
            command.push(String(width));
        greetdSync.command = command;
        greetdSync.running = true;
    }

    function greetdFinished() {
        greetdBusy = false;
        if (greetdNext)
            startGreetd();
        else
            checkApplied();
    }

    function startSddm() {
        const job = sddmNext;
        sddmNext = null;
        sddmBusy = true;
        sddmSync.pending = true;
        sddmSync.didStart = false;
        sddmSync.command = ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/sddm-sync.py").toString().replace(/^file:\/\//, "")), job.path, job.palette, root.sddmDataDir];
        sddmSync.running = true;
    }

    function sddmFinished() {
        sddmBusy = false;
        if (sddmNext) {
            startSddm();
            return;
        }
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
            paletteProc.pendingPath = job.path;
            paletteProc.epoch = root.paletteEpoch;
            const mode = root.mode;
            frameFor(job.path, "palette", path => {
                paletteProc.pending = true;
                paletteProc.didStart = false;
                paletteProc.command = ThemeLogic.dryArgs(path, mode);
                paletteProc.running = true;
            }, reason => root.paletteFailed(reason));
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

    Connections {
        target: Wallpapers

        function onSavedChanged() {
            if (Wallpapers.saved)
                root.restorePalettes();
        }
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
                mode: root.mode,
                variant: root.variant
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
        id: probe

        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                root.frameFailed("can't read the video duration");
            }
        }

        stdout: StdioCollector {
            id: probeOut

            onStreamFinished: {
                if (!probe.pending)
                    return;
                probe.pending = false;
                const job = root.frameJob;
                if (!job)
                    return;
                const seconds = ThemeLogic.midpoint(probeOut.text);
                if (seconds === null)
                    return root.frameFailed("no duration in " + job.path);
                extract.pending = true;
                extract.didStart = false;
                extract.command = ThemeLogic.frameArgs(job.path, seconds, job.output);
                extract.running = true;
            }
        }
    }

    Process {
        id: extract

        property bool pending: false
        property bool didStart: false

        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                root.frameFailed("can't extract a frame from " + (root.frameJob?.path ?? "the video"));
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0) {
                root.frameFailed("can't extract a frame from " + (root.frameJob?.path ?? "the video"));
                return;
            }
            root.frameReady();
        }
    }

    Process {
        id: appProc

        // A binary that cannot start never emits `exited`: `onStarted` stays
        // false and `running` drops back, which is the only failure signal.
        property bool pending: false
        property bool didStart: false
        // The variant this run themes the apps in; the post-hook gets the same.
        property string variant: "dark"

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
            // A dark colors.json fits the notch again; dropping the shared
            // palette only now keeps the light one from flashing meanwhile.
            if (variant === "dark")
                root.sharedPalette = null;
            postHook.pending = true;
            postHook.didStart = false;
            postHook.command = [root.postHookPath, variant];
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
                // Light apps leave colors.json light: the greeter is staged from
                // the shared dark dry-run instead.
                if (appProc.variant === "dark")
                    root.stageSddm(root.appBackground, root.configHome + "/matugen/colors.json");
                root.appFinished();
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0)
                console.warn("Theme: post-hook exited with " + code);
            if (appProc.variant === "dark")
                root.stageSddm(root.appBackground, root.configHome + "/matugen/colors.json");
            root.appFinished();
        }
    }

    Process {
        id: greetdSync
        property bool pending: false
        property bool didStart: false
        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                console.warn("Theme: can't start greetd staging");
                root.greetdFinished();
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0)
                console.warn("Theme: greetd staging exited with " + code);
            root.greetdFinished();
        }
    }

    Process {
        id: sddmSync
        property bool pending: false
        property bool didStart: false
        onStarted: didStart = true
        onRunningChanged: {
            if (!running && pending && !didStart) {
                pending = false;
                console.warn("Theme: can't start SDDM staging");
                root.sddmFinished();
            }
        }
        onExited: code => {
            pending = false;
            if (code !== 0)
                console.warn("Theme: SDDM staging exited with " + code);
            root.sddmFinished();
        }
    }

    Process {
        id: paletteProc

        property string pendingScreen: ""
        property string pendingPath: ""
        property int epoch: 0
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
                // A shared commit cleared this monitor's override meanwhile.
                if (paletteProc.epoch !== root.paletteEpoch) {
                    root.paletteBusy = false;
                    root.startPalette();
                    return;
                }
                const palette = ThemeLogic.parseDryPalette(paletteOut.text);
                // The empty screen is the shared wallpaper's notch palette.
                if (palette) {
                    if (paletteProc.pendingScreen === "") {
                        root.sharedPalette = palette;
                    } else {
                        const next = Object.assign({}, root.palettes);
                        next[paletteProc.pendingScreen] = palette;
                        root.palettes = next;
                    }
                    // The greeter shows the notch look: always a dark palette.
                    if (paletteProc.pendingPath === root.sddmWallpaper)
                        root.stageSddm(paletteProc.pendingPath, JSON.stringify({
                            colors: {
                                primary: {
                                    hex: palette.primary
                                },
                                on_surface: {
                                    hex: palette.onSurface
                                }
                            }
                        }));
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
        property int epoch: 0
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
                // The wallpaper changed while this preview was being computed.
                if (previewProc.epoch !== root.previewEpoch) {
                    root.previewBusy = false;
                    root.startPreview();
                    return;
                }
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
