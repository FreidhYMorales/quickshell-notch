import QtQuick
import "../services"
import "../logic/wallpaperState.mjs" as WallpaperState

// Precomputes one monitor's theme swatches whenever its committed wallpaper
// changes, so the theme view opens with them already in the cache.
QtObject {
    id: root

    required property string monitorName

    readonly property string wallpaper: WallpaperState.warmupPath(Theme.loaded && Wallpapers.saved, Wallpapers.perScreen, Wallpapers.fallback, monitorName)

    // Deferred: a wallpaper commit updates the state before it tells Theme,
    // which then drops the preview queue.
    onWallpaperChanged: Qt.callLater(warm)
    Component.onCompleted: Qt.callLater(warm)

    function warm() {
        if (wallpaper)
            Theme.generatePreviews(monitorName);
    }
}
