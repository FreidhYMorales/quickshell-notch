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
    property bool capturing: false
    readonly property string captureDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-notch-lock-" + (Quickshell.env("USER") || "user")
    property int captureRevision: 0
    readonly property int morphDuration: 520

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
            if (lock.locked)
                return;
            exitMorph.stop();
            root.exiting = false;
            root.reveal = 0;
            root.entering = true;
            root.capturing = true;
            capture.command = ["sh", "-c", 'umask 077; mkdir -p -m 700 "$1" || exit 1; dir="$1"; shift; for monitor do grim -o "$monitor" "$dir/$monitor.png" || exit 1; done', "capture", root.captureDir].concat(Quickshell.screens.map(s => s.name));
            capture.running = true;
        }
    }

    Process {
        id: capture
        onExited: code => {
            root.capturing = false;
            if (!root.entering) return;
            if (code === 0) root.captureRevision++;
            else console.warn("Lock: grim capture failed, falling back to wallpaper");
            lock.locked = true;
        }
    }

    Process {
        id: cleanupCapture
        command: ["rm", "-rf", root.captureDir]
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

    NumberAnimation {
        id: exitMorph
        target: root
        property: "reveal"
        from: 1
        to: 0
        duration: root.morphDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            // Never release a session lock before PAM has succeeded.
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
            }
            else {
                enterMorph.stop();
                exitMorph.stop();
                sharedAuth.stop();
                root.exiting = false;
                root.entering = false;
                root.reveal = 1;
                cleanupCapture.running = true;
            }
        }
        onSecureChanged: {
            Session.setSecure(secure);
            if (secure && root.entering && lock.locked) {
                root.entering = false;
                if (lock.secure)
                    enterMorph.restart();
            }
        }

        WlSessionLockSurface {
            id: surface
            color: Colours.background

            // Always cover the compositor while locked. The wallpaper is a
            // safe, static backdrop; the morph itself is a visible Shape,
            // not a texture mask (which could turn the notch invisible).
            readonly property string captureSource: root.captureRevision > 0 && surface.screen ? "file://" + root.captureDir + "/" + surface.screen.name + ".png?v=" + root.captureRevision : ""
            readonly property string wallpaperPath: surface.screen ? Wallpapers.pathFor(surface.screen.name) : ""
            property bool videoFrameReady: false
            onVideoWallpaperChanged: videoFrameReady = false
            readonly property bool videoWallpaper: WallpaperState.isVideoPath(wallpaperPath)
            readonly property string wallpaperSource: WallpaperState.isVideoPath(wallpaperPath) ? Wallpapers.thumbnailFor(wallpaperPath) : (wallpaperPath === "" ? "" : "file://" + wallpaperPath)
            readonly property real idleWidth: Math.max(80, CenterStore.idleNotchWidths[surface.screen?.name] || 300)
            readonly property real morphWidth: idleWidth + (width - idleWidth) * root.reveal
            readonly property real morphHeight: Layout.idleHeight + (height - Layout.idleHeight) * root.reveal
            readonly property real ear: Layout.earRadius * (1 - root.reveal)
            readonly property real corner: Layout.cornerRadius * (1 - root.reveal)

            // Match QuickWallpaperSurface: a full-screen wallpaper is drawn
            // inside a growing, curved reveal frame. The surrounding secure
            // surface uses the same wallpaper, without tint or blur.
            Image {
                anchors.fill: parent
                source: surface.captureSource || surface.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
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
                        path: EarGeometry.notchPath(revealMask.width, revealMask.height,
                            Layout.earRadius * (1 - surface.earMorph),
                            Layout.cornerRadius * (1 - surface.cornerMorph))
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
                        visible: !surface.videoWallpaper || !surface.videoFrameReady
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    MediaPlayer {
                        id: lockVideo
                        source: surface.videoWallpaper ? "file://" + surface.wallpaperPath : ""
                        videoOutput: lockVideoOutput
                        loops: MediaPlayer.Infinite
                        audioOutput: AudioOutput { muted: true }
                        onSourceChanged: if (surface.videoWallpaper && lock.locked) play()
                        Component.onCompleted: if (surface.videoWallpaper && lock.locked) play()
                        onMediaStatusChanged: {
                            if (surface.videoWallpaper && lock.locked && (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) && playbackState !== MediaPlayer.PlayingState)
                                play();
                        }
                        onErrorOccurred: (error, message) => console.warn("Lock video: " + message)
                    }

                    Connections {
                        target: lock
                        function onLockedChanged() {
                            if (lock.locked && surface.videoWallpaper) lockVideo.play();
                            else lockVideo.stop();
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
            Shape {
                id: lockedNotch
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: surface.idleWidth
                height: Layout.idleHeight
                visible: root.reveal >= 0.995 && !root.exiting
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Colours.background
                    strokeWidth: -1
                    PathSvg { path: EarGeometry.notchPath(lockedNotch.width, lockedNotch.height, Layout.earRadius, Layout.cornerRadius) }
                }
                Text {
                    anchors.centerIn: parent
                    text: "🔒"
                    color: "white"
                    font.pixelSize: 21
                }
            }
        }
    }
}
