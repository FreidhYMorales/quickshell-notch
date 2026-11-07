import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import "../services"
import "../logic/wallpaperState.mjs" as WallpaperState

// One always-mapped background-layer surface per monitor drawing that
// monitor's wallpaper (image or video). Transparent until the frame is ready,
// so hyprpaper below stays visible meanwhile.
PanelWindow {
    id: root

    readonly property string path: Wallpapers.pathFor(screen.name)
    readonly property bool isVideo: WallpaperState.isVideoPath(path)
    readonly property url source: path === "" ? "" : "file://" + path
    readonly property bool playing: WallpaperState.videoShouldPlay(path, Session.locked)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    // Empty mask: every click reaches the desktop.
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "notch-wallpaper"

    Image {
        anchors.fill: parent
        visible: !root.isVideo
        source: root.isVideo ? "" : root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        onStatusChanged: {
            if (status === Image.Error)
                console.warn("WallpaperSurface: cannot load " + root.path);
        }
    }

    Video {
        id: video

        anchors.fill: parent
        visible: root.isVideo
        source: root.isVideo ? root.source : ""
        autoPlay: false
        // A video-to-video wallpaper switch keeps root.playing true, so
        // onPlayingChanged alone cannot start the newly selected source.
        onSourceChanged: {
            if (root.playing && root.isVideo)
                play();
            else
                stop();
        }
        loops: MediaPlayer.Infinite
        muted: true
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: hasVideo ? 1 : 0
        onErrorOccurred: (error, errorString) => console.warn("WallpaperSurface: cannot play " + root.path + ": " + errorString)
    }

    onPlayingChanged: {
        if (playing)
            video.play();
        else
            video.pause();
    }

    // Caffeine: this surface is always mapped, so the inhibitor holds from
    // the moment it is enabled.
    IdleInhibitor {
        enabled: Caffeine.enabled
        window: root
    }
}
