import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import "../services"
import "../config"
import "../logic/wallpaperState.mjs" as WallpaperState

// Double-buffered wallpaper per monitor. Keep the previous frame visible
// until the next image is decoded or the next video has a frame.
PanelWindow {
    id: root

    readonly property string path: Wallpapers.pathFor(screen.name)
    property int frontSlot: 0
    property int incomingSlot: -1
    property bool transitioning: false
    property real fade: 1
    property bool initialized: false

    function slot(index) {
        return layers.itemAt(index);
    }

    function requestWallpaper(path) {
        if (!slot(0) || !slot(1))
            return;
        if (!initialized) {
            initialized = true;
            const first = slot(frontSlot);
            if (first)
                first.wallpaperPath = path;
            return;
        }
        const front = slot(frontSlot);
        if (front && front.wallpaperPath === path && incomingSlot < 0)
            return;
        // Restart a pending transition from the currently visible frame.
        fadeAnimation.stop();
        transitioning = false;
        const pending = incomingSlot >= 0 ? slot(incomingSlot) : null;
        if (pending)
            pending.wallpaperPath = "";
        incomingSlot = 1 - frontSlot;
        fade = 0;
        const next = slot(incomingSlot);
        if (next)
            next.wallpaperPath = path;
        if (path === "")
            incomingReady();
    }

    function incomingReady() {
        if (incomingSlot < 0 || transitioning)
            return;
        transitioning = true;
        fadeAnimation.restart();
    }

    function completeTransition() {
        if (!transitioning || incomingSlot < 0)
            return;
        const old = slot(frontSlot);
        frontSlot = incomingSlot;
        incomingSlot = -1;
        transitioning = false;
        fade = 1;
        if (old)
            old.wallpaperPath = "";
    }

    onPathChanged: requestWallpaper(path)
    Component.onCompleted: requestWallpaper(path)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "notch-wallpaper"

    NumberAnimation {
        id: fadeAnimation
        target: root
        property: "fade"
        from: 0
        to: 1
        duration: 350
        easing.type: Easing.InOutCubic
        onFinished: root.completeTransition()
    }

    Repeater {
        id: layers
        model: 2

        delegate: Item {
            id: layer
            required property int index
            property string wallpaperPath: ""
            readonly property bool videoFile: WallpaperState.isVideoPath(wallpaperPath)
            readonly property url mediaSource: wallpaperPath ? "file://" + wallpaperPath : ""
            readonly property bool isFront: index === root.frontSlot
            readonly property bool isIncoming: index === root.incomingSlot
            readonly property bool playVideo: videoFile && !Session.locked && (isFront || isIncoming)
            anchors.fill: parent
            visible: isFront || isIncoming
            z: isIncoming ? 1 : 0
            opacity: isIncoming ? root.fade : 1

            Image {
                id: still
                anchors.fill: parent
                visible: !layer.videoFile
                source: layer.videoFile ? "" : layer.mediaSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Ready && layer.isIncoming)
                        root.incomingReady();
                    if (status === Image.Error)
                        console.warn("WallpaperSurface: cannot load " + layer.wallpaperPath);
                }
            }

            Video {
                id: movie
                anchors.fill: parent
                visible: layer.videoFile
                source: layer.videoFile ? layer.mediaSource : ""
                autoPlay: false
                loops: MediaPlayer.Infinite
                muted: true
                fillMode: VideoOutput.PreserveAspectCrop
                onSourceChanged: {
                    if (layer.playVideo)
                        play();
                    else
                        stop();
                }
                onHasVideoChanged: {
                    if (hasVideo && layer.isIncoming)
                        root.incomingReady();
                }
                onErrorOccurred: (error, errorString) =>
                    console.warn("WallpaperSurface: cannot play " + layer.wallpaperPath + ": " + errorString)
            }

            onPlayVideoChanged: {
                if (playVideo)
                    movie.play();
                else
                    movie.pause();
            }
            onIsIncomingChanged: {
                if (isIncoming && (videoFile ? movie.hasVideo : still.status === Image.Ready))
                    root.incomingReady();
            }
        }
    }

    IdleInhibitor {
        enabled: Caffeine.enabled
        window: root
    }
}
