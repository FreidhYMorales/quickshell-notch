import QtQuick
import Quickshell

ShellRoot {
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var wallpapers: Services.Wallpapers }', this)
    Timer {
        interval: 50
        running: true
        onTriggered: {
            console.log("wallpaper all by default: " + services.wallpapers.applyToAll);
            services.wallpapers.setApplyToAll(false);
            console.log("wallpaper individual selectable: " + !services.wallpapers.applyToAll);
            Qt.exit(0);
        }
    }
}
