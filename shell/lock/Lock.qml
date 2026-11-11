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

// The compositor keeps every monitor covered by WlSessionLockSurface for the
// entire morph. Only successful PAM authentication may begin the exit.
Scope {
    id: root

    property real reveal: 1
    property bool exiting: false
    property bool entering: false
    property bool notchShown: false
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
        if (!lock.locked || root.exiting)
            return;
        root.exiting = true;
        exitMorph.restart();
    }

    LockPam {
        id: sharedAuth
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
                sharedAuth.stop();
                root.exiting = false;
                root.entering = false;
                root.reveal = 1;
                root.notchShown = false;
                curtainEntrance.stop();
                notchRetreat.stop();
                root.releaseFrames();
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
                        anchors.fill: parent
                        auth: sharedAuth
                        screen: surface.screen
                        enabled: !root.exiting && root.reveal >= 0.98
                        opacity: Math.max(0, Math.min(1, (root.reveal - 0.5) * 2))
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
                visible: root.notchShown || notchDrop.running
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
