pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../notches/center"
import "../logic/earGeometry.mjs" as EarGeometry
import "../logic/wallpaperState.mjs" as WallpaperState
import "../logic/lockSecurity.mjs" as LockSecurity
import "../logic/lockStage.mjs" as LockStage

// The compositor keeps every monitor covered by WlSessionLockSurface for the
// entire morph. Only successful PAM authentication may begin the exit.
Scope {
    id: root

    property real reveal: 1
    property bool exiting: false
    property bool entering: false
    property bool notchShown: false
    // The layer painted over the lock look while the idle stages are up:
    // 1 is fullscreen and 0 has contracted into the notch. `overlayKind` keeps
    // what it paints once the stage itself is already gone.
    property real overlay: 0
    property string overlayKind: ""
    readonly property string stage: Session.stage
    // Last outputs state handed to the compositor (they start on).
    property bool outputsOn: true
    // True from the input that ends the black stage until the outputs are
    // back: the frame stays full screen black meanwhile.
    property bool wakingBlack: false
    property double wakeStarted: 0
    // Last `dpms on` sent while waking, so the retries cannot chain forever.
    property double dpmsOnAt: 0
    // Screen name -> LockFrame. Filled by the hidden capture hosts below.
    property var frames: ({})
    readonly property int morphDuration: 520

    function frameFor(name: string): var {
        return root.frames[name] ? root.frames[name] : null;
    }

    // Start one capture per screen and let the gate decide when the lock may
    // be requested: as soon as every frame is ready, or at the short deadline.
    function startCapture(): void {
        const screens = Quickshell.screens;
        const names = [];
        for (let i = 0; i < screens.length; ++i)
            names.push(screens[i].name);
        frameGate.start(names);
        for (let i = 0; i < screens.length; ++i) {
            const frame = root.frameFor(screens[i].name);
            if (frame)
                frame.start(screens[i], frameGate.generation);
            else
                frameGate.failed(screens[i].name, frameGate.generation);
        }
    }

    function releaseFrames(): void {
        for (const name in root.frames) {
            if (root.frames[name])
                root.frames[name].release();
        }
    }

    function startExit() {
        if (!lock.locked || root.exiting || root.stage !== "normal")
            return;
        root.exiting = true;
        exitMorph.restart();
    }

    // What an idle stage asks of the shell: hide the pointer, keep or drop the
    // outputs, and paint its layer over the lock look. The black stage paints
    // first and lets `blackOut` drop the outputs once the frame is up.
    function applyStage(): void {
        const effects = LockStage.stageEffects(root.stage);
        Hypr.setPointerHidden(effects.pointerHidden);
        if (effects.outputsOn) {
            blackOut.stop();
            overlayEnter.stop();
            if (!root.outputsOn) {
                Hypr.setOutputsOn(true);
                root.outputsOn = true;
            }
        }
        if (effects.overlay !== null) {
            overlayExit.stop();
            root.overlayKind = effects.overlay;
            if (effects.overlay === "black") {
                root.notchShown = false;
                root.overlay = 0;
                overlayEnter.restart();
            } else {
                root.overlay = 1;
            }
        } else if (!root.wakingBlack && LockStage.overlayMustContract(root.overlayKind, root.stage)) {
            // The stage left without an input (a manual lock request while the
            // screensaver is up): contract the layer it left over the form.
            root.notchShown = true;
            overlayExit.restart();
        }
    }

    // Any input ends a screensaver or black stage. The lock look is already
    // painted underneath, so it comes out as that layer contracts into the
    // notch with the lock's own morph. The surface passes its content item:
    // ids declared inside WlSessionLockSurface are not visible out here.
    //
    // The black stage first has to bring the outputs back: the frame stays
    // full screen while the panel wakes, so the contraction is not spent in
    // the dark. `wakingBlack` keeps that wait apart from the stage itself,
    // which the lock has already left.
    function wakeStage(content: var): void {
        if (root.stage === "normal")
            return;
        const black = root.stage === "black";
        const blackComplete = root.overlay >= 0.999;
        if (black && blackComplete) {
            // Flag the wake before the stage goes away, so the stage change does
            // not contract the frame before the outputs are back.
            root.wakingBlack = true;
            root.wakeStarted = Date.now();
            root.dpmsOnAt = 0;
        }
        Session.endStage();
        content.wake();
        if (black) {
            if (!blackComplete) {
                root.overlay = 1;
                root.notchShown = true;
                overlayExit.restart();
                return;
            }
            root.wakeOutputs();
            wakePoll.restart();
            return;
        }
        root.notchShown = true;
        overlayExit.restart();
    }

    // Asks the compositor for the outputs again, at most every other poll.
    // The `dpms off` of the black stage and the `dpms on` of the wake are two
    // detached hyprctl calls: when they land out of order the panel stays
    // dark, so the wake keeps insisting until the probe sees it lit.
    function wakeOutputs(): void {
        const now = Date.now();
        if (now - root.dpmsOnAt < Timings.lockWakePoll * 2)
            return;
        root.dpmsOnAt = now;
        Hypr.setOutputsOn(true);
    }

    // The black frame contracts once the outputs are lit (or once waiting for
    // them would be worse than a missed animation). The notch drops in with
    // the contraction, so the black sheet is what forms it.
    function finishWake(): void {
        if (!root.wakingBlack)
            return;
        root.wakingBlack = false;
        wakePoll.stop();
        dpmsProbe.running = false;
        // One last idempotent wake in case the black stage's `dpms off` was
        // still in flight when the probe first saw the panel lit.
        Hypr.setOutputsOn(true);
        if (!lock.locked || root.exiting)
            return;
        root.notchShown = true;
        overlayExit.restart();
    }

    // A probe only counts once the panel has had `lockWakeDelay` to light up.
    function wakeReady(json: string): bool {
        return LockStage.wakeReady(Date.now() - root.wakeStarted, json, Timings.lockWakeDelay, Timings.lockWakeTimeout);
    }

    onStageChanged: root.applyStage()
    Component.onCompleted: root.applyStage()
    // Never leave the pointer hidden or the outputs off behind us.
    Component.onDestruction: {
        Hypr.setPointerHidden(false);
        Hypr.setOutputsOn(true);
    }

    LockPam {
        id: sharedAuth
        stage: root.stage
        fingerprintEnabled: LockSecurity.fingerprintEnabled(notchSecurity.loaded ? notchSecurity.text() : null, oldSecurity.loaded ? oldSecurity.text() : null)
        onUnlocked: root.startExit()
    }

    FileView {
        id: notchSecurity
        path: Wallpapers.notchDir + "/security.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: oldSecurity
        path: Wallpapers.oldDir + "/security.json"
        blockLoading: true
        printErrors: false
    }

    Connections {
        target: Session
        function onLockRequested() {
            if (lock.locked || frameGate.pending)
                return;
            exitMorph.stop();
            notchRetreat.stop();
            root.wakingBlack = false;
            wakePoll.stop();
            dpmsProbe.running = false;
            root.exiting = false;
            curtainEntrance.stop();
            root.notchShown = false;
            root.reveal = 0;
            root.entering = true;
            root.startCapture();
        }
    }

    // Waiting a frame is cosmetic: the gate always finishes, and a missing
    // frame simply leaves the wallpaper in place.
    LockFrameGate {
        id: frameGate
        timeout: Timings.lockCaptureTimeout
        onFinished: reason => {
            if (!root.entering)
                return;
            if (reason !== "ready")
                console.warn("Lock: capture incomplete (" + reason + "), keeping wallpaper on screens without a frame");
            lock.locked = true;
        }
    }

    // A hidden 1x1 layer surface per screen owns the capture view until the
    // compositor confirms the lock, then the frame moves into the secure
    // surface. Captures never run while the shell is unlocked.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: frameHost
            required property var modelData
            screen: modelData
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            LockFrame {
                id: frame
                anchors.fill: parent
                onFrameReady: attempt => frameGate.ready(frameHost.modelData.name, attempt)
                onFrameFailed: attempt => frameGate.failed(frameHost.modelData.name, attempt)
                Component.onCompleted: {
                    root.frames[frameHost.modelData.name] = frame;
                }
                Component.onDestruction: {
                    if (root.frames[frameHost.modelData.name] === frame)
                        delete root.frames[frameHost.modelData.name];
                }
            }
        }
    }

    NumberAnimation {
        id: enterMorph
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
    }

    // The idle layer contracts into the notch, uncovering the lock form that
    // was already painted underneath.
    NumberAnimation {
        id: overlayEnter
        target: root
        property: "overlay"
        from: 0
        to: 1
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            if (root.stage === "black" && root.outputsOn)
                blackOut.restart();
        }
    }

    NumberAnimation {
        id: overlayExit
        target: root
        property: "overlay"
        from: 1
        to: 0
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            root.overlayKind = "";
        }
    }

    // While the black stage wakes, ask the compositor every `lockWakePoll` ms
    // whether every output is back on. The frame stays put until it is.
    Timer {
        id: wakePoll
        interval: Timings.lockWakePoll
        repeat: true
        onTriggered: {
            if (!root.wakingBlack) {
                stop();
                return;
            }
            if (Date.now() - root.wakeStarted >= Timings.lockWakeTimeout) {
                console.warn("Lock: the outputs did not come back before the wake deadline");
                root.finishWake();
                return;
            }
            root.wakeOutputs();
            if (!dpmsProbe.running)
                dpmsProbe.running = true;
        }
    }

    // The outputs go off only once the black frame has been up for a moment.
    Timer {
        id: blackOut
        interval: Timings.lockBlackDelay
        repeat: false
        onTriggered: {
            if (root.stage !== "black")
                return;
            Hypr.setOutputsOn(false);
            root.outputsOn = false;
        }
    }

    Process {
        id: dpmsProbe
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.wakingBlack && root.wakeReady(text))
                    root.finishWake();
            }
        }
    }

    Timer {
        id: curtainEntrance
        interval: 440
        repeat: false
        onTriggered: if (lock.locked && root.entering && !root.exiting) {
            root.entering = false;
            enterMorph.restart();
        }
    }

    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        from: 1
        to: 0
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            // Keep the secure surface until the black notch has slid away.
            if (root.exiting && lock.locked) {
                root.notchShown = false;
                notchRetreat.restart();
            }
        }
    }

    Timer {
        id: notchRetreat
        interval: 440
        repeat: false
        onTriggered: {
            if (root.exiting && lock.locked) {
                lock.locked = false;
                Session.setLocked(false);
                Session.setSecure(false);
            }
        }
    }

    WlSessionLock {
        id: lock

        onLockedChanged: {
            Session.setLocked(locked);
            if (locked) {
                sharedAuth.listen();
            } else {
                enterMorph.stop();
                exitMorph.stop();
                overlayExit.stop();
                overlayEnter.stop();
                wakePoll.stop();
                dpmsProbe.running = false;
                sharedAuth.stop();
                root.exiting = false;
                root.entering = false;
                root.wakingBlack = false;
                root.reveal = 1;
                root.overlay = 0;
                root.overlayKind = "";
                root.notchShown = false;
                curtainEntrance.stop();
                notchRetreat.stop();
                root.releaseFrames();
                // A lock that ends outside the idle chain must not leave the
                // pointer hidden or the outputs off.
                if (root.stage !== "normal")
                    Session.endStage();
            }
        }
        onSecureChanged: {
            Session.setSecure(secure);
            if (secure && root.entering && lock.locked) {
                // First cover the desktop notch with the secure curtain.
                root.notchShown = true;
                curtainEntrance.restart();
            }
        }

        WlSessionLockSurface {
            id: surface
            color: Colours.background

            // Always cover the compositor while locked. The wallpaper is a
            // safe, static backdrop; the morph itself is a visible Shape,
            // not a texture mask (which could turn the notch invisible).
            readonly property var lockFrame: surface.screen ? root.frameFor(surface.screen.name) : null
            readonly property bool captureShown: surface.lockFrame !== null && surface.lockFrame.hasContent && surface.lockFrame.visualParent === captureLayer
            readonly property string wallpaperPath: surface.screen ? Wallpapers.pathFor(surface.screen.name) : ""
            property bool videoFrameReady: false
            onVideoWallpaperChanged: videoFrameReady = false
            readonly property bool videoWallpaper: WallpaperState.isVideoPath(wallpaperPath)
            // The black stage leaves the surface's own black: no wallpaper,
            // captured frame or padlock. The lock look stays painted
            // underneath so the layer above can contract over it.
            readonly property bool blackLook: Session.stage === "black"
            readonly property bool gifWallpaper: /\.gif$/i.test(wallpaperPath)
            readonly property string wallpaperSource: WallpaperState.isVideoPath(wallpaperPath) ? Wallpapers.thumbnailFor(wallpaperPath) : (wallpaperPath === "" ? "" : "file://" + wallpaperPath)
            readonly property real idleWidth: Math.max(80, CenterStore.idleNotchWidths[surface.screen?.name] || 300)
            readonly property real morphWidth: idleWidth + (width - idleWidth) * root.reveal
            readonly property real morphHeight: Layout.idleHeight + (height - Layout.idleHeight) * root.reveal
            readonly property real ear: Layout.earRadius * (1 - root.reveal)
            readonly property real corner: Layout.cornerRadius * (1 - root.reveal)

            // Match QuickWallpaperSurface: a full-screen wallpaper is drawn
            // inside a growing, curved reveal frame. The surrounding secure
            // surface shows the frozen desktop frame, or the wallpaper when
            // the capture did not make it in time.
            Item {
                id: captureLayer
                anchors.fill: parent
                visible: surface.captureShown

                Component.onDestruction: if (surface.lockFrame && surface.lockFrame.visualParent === captureLayer)
                    surface.lockFrame.release()
            }

            Image {
                anchors.fill: parent
                source: surface.wallpaperSource
                visible: !surface.captureShown
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
            }

            // Frames live in their own window until the surface exists. Attach
            // as soon as the surface knows its screen, before the compositor
            // shows it, so the first painted frame is the frozen desktop and
            // never the wallpaper.
            function attachCapture(): void {
                if (!surface.screen)
                    return;
                const frame = root.frameFor(surface.screen.name);
                if (frame && frame.hasContent)
                    frame.attach(captureLayer);
            }

            Component.onCompleted: surface.attachCapture()
            onScreenChanged: surface.attachCapture()

            Connections {
                target: lock
                function onSecureChanged() {
                    if (lock.secure)
                        surface.attachCapture();
                }
            }

            // A locked notch stays visible once the reveal reaches fullscreen.
            // Its lock glyph yields to the real desktop notch after unlock.
            readonly property real earMorph: {
                const t = Math.max(0, Math.min(1, (root.reveal - 0.45) / 0.55));
                return t * t * (3 - 2 * t);
            }
            readonly property real cornerMorph: {
                const t = Math.max(0, Math.min(1, (root.reveal - 0.20) / 0.80));
                return t * t * (3 - 2 * t);
            }

            Shape {
                id: revealMask
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: revealFrame.width
                height: revealFrame.height
                visible: false
                layer.enabled: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "white"
                    strokeWidth: -1
                    PathSvg {
                        path: EarGeometry.notchPath(revealMask.width, revealMask.height, Layout.earRadius * (1 - surface.earMorph), Layout.cornerRadius * (1 - surface.cornerMorph))
                    }
                }
            }

            Rectangle {
                id: revealFrame
                width: surface.morphWidth
                height: surface.morphHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                color: Colours.background
                clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: revealMask
                }

                Item {
                    width: surface.width
                    height: surface.height
                    x: -revealFrame.x

                    Image {
                        anchors.fill: parent
                        source: surface.wallpaperSource
                        visible: !surface.gifWallpaper && (!surface.videoWallpaper || !surface.videoFrameReady)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    AnimatedImage {
                        anchors.fill: parent
                        source: surface.gifWallpaper ? "file://" + surface.wallpaperPath : ""
                        visible: surface.gifWallpaper
                        playing: surface.gifWallpaper && lock.locked
                        fillMode: Image.PreserveAspectCrop
                        onStatusChanged: if (status === Image.Error)
                            console.warn("Lock GIF: cannot load " + surface.wallpaperPath)
                    }

                    MediaPlayer {
                        id: lockVideo
                        source: surface.videoWallpaper ? "file://" + surface.wallpaperPath : ""
                        videoOutput: lockVideoOutput
                        loops: MediaPlayer.Infinite
                        audioOutput: AudioOutput {
                            muted: true
                        }
                        onSourceChanged: if (surface.videoWallpaper && lock.locked)
                            play()
                        Component.onCompleted: if (surface.videoWallpaper && lock.locked)
                            play()
                        onMediaStatusChanged: {
                            if (surface.videoWallpaper && lock.locked && (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) && playbackState !== MediaPlayer.PlayingState)
                                play();
                        }
                        onErrorOccurred: (error, message) => console.warn("Lock video: " + message)
                    }

                    Connections {
                        target: lock
                        function onLockedChanged() {
                            if (lock.locked && surface.videoWallpaper)
                                lockVideo.play();
                            else
                                lockVideo.stop();
                        }
                    }

                    VideoOutput {
                        id: lockVideoOutput
                        anchors.fill: parent
                        visible: surface.videoWallpaper && surface.videoFrameReady
                        fillMode: VideoOutput.PreserveAspectCrop
                    }

                    Connections {
                        target: lockVideoOutput.videoSink
                        function onVideoFrameChanged(frame) {
                            if (surface.videoWallpaper && lock.locked)
                                surface.videoFrameReady = true;
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#44000000"
                    }

                    LockContent {
                        id: content

                        anchors.fill: parent
                        auth: sharedAuth
                        screen: surface.screen
                        stage: Session.stage
                        enabled: !root.exiting && root.reveal >= 0.98
                        opacity: Math.max(0, Math.min(1, (root.reveal - 0.5) * 2))
                        onWoke: root.wakeStage(content)
                    }
                }
            }

            // The idle stage layer: the monitor's own wallpaper for the
            // screensaver, pure black for the stage with the outputs off. It
            // follows the entrance morph and contracts into the notch when an
            // input ends the stage, uncovering the lock look below.
            readonly property bool overlayShown: root.overlayKind !== "" && Math.min(root.reveal, root.overlay) > 0.001
            readonly property real overlayMorph: Math.min(root.reveal, root.overlay)
            readonly property real overlayWidth: surface.idleWidth + (surface.width - surface.idleWidth) * surface.overlayMorph
            readonly property real overlayHeight: Layout.idleHeight + (surface.height - Layout.idleHeight) * surface.overlayMorph

            Shape {
                id: overlayMask
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: overlayFrame.width
                height: overlayFrame.height
                visible: false
                layer.enabled: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "white"
                    strokeWidth: -1
                    PathSvg {
                        path: EarGeometry.notchPath(overlayMask.width, overlayMask.height, Layout.earRadius * (1 - surface.overlayMorph), Layout.cornerRadius * (1 - surface.overlayMorph))
                    }
                }
            }

            Rectangle {
                id: overlayFrame
                width: surface.overlayWidth
                height: surface.overlayHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                color: Colours.background
                clip: true
                visible: surface.overlayShown
                layer.enabled: surface.overlayShown
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: overlayMask
                }

                Item {
                    width: surface.width
                    height: surface.height
                    x: -overlayFrame.x

                    Image {
                        anchors.fill: parent
                        source: root.overlayKind === "wallpaper" ? surface.wallpaperSource : ""
                        visible: root.overlayKind === "wallpaper" && !surface.gifWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    AnimatedImage {
                        anchors.fill: parent
                        source: root.overlayKind === "wallpaper" && surface.gifWallpaper ? "file://" + surface.wallpaperPath : ""
                        visible: root.overlayKind === "wallpaper" && surface.gifWallpaper
                        playing: surface.overlayShown
                        fillMode: Image.PreserveAspectCrop
                        onStatusChanged: if (status === Image.Error)
                            console.warn("Lock screensaver GIF: cannot load " + surface.wallpaperPath)
                    }
                }
            }

            // A separate secure notch drops from the top after the reveal.
            // Keep it above the contracting frame until the compositor unlocks.
            // The desktop notch is hidden by the secure compositor layer.
            // Draw its normal idle state underneath the black lock curtain,
            // then release the secure surface after the curtain retreats.
            Item {
                id: notchBase
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: surface.idleWidth
                height: Layout.idleHeight
                z: 9
                visible: (root.entering && root.reveal <= 0.001) || (root.exiting && root.reveal <= 0.001)

                CenterIdle {
                    anchors.fill: parent
                    screen: surface.screen
                    view: CenterStore.viewFor(surface.screen?.name || "")
                }
            }

            Item {
                id: lockedNotch
                anchors.horizontalCenter: parent.horizontalCenter
                width: surface.idleWidth
                height: Layout.idleHeight
                y: root.notchShown ? 0 : -height
                visible: (root.notchShown || notchDrop.running) && !surface.blackLook
                z: 10

                Behavior on y {
                    NumberAnimation {
                        id: notchDrop
                        duration: 420
                        easing.type: root.exiting ? Easing.InCubic : Easing.OutCubic
                    }
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: Colours.background
                        strokeWidth: -1
                        PathSvg {
                            path: EarGeometry.notchPath(lockedNotch.width, lockedNotch.height, Layout.earRadius, Layout.cornerRadius)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf023"
                    font.family: Fonts.family
                    font.pixelSize: Fonts.idleClock + 3
                    color: Colours.paletteFor(surface.screen).onSurface
                }
            }
        }
    }
}
