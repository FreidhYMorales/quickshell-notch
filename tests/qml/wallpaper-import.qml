import QtQuick
import QtTest
import Quickshell

ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var wallpapers: Services.Wallpapers }', root)
    TestCase {
        name: "WallpaperImport"
        when: true
        function test_import() {
            const wallpapers = root.services.wallpapers;
            for (let i = 0; i < 50 && !wallpapers.saved; i++)
                wait(100);
            console.log("wallpaper saved: " + wallpapers.saved);
            console.log("wallpaper DP-1: " + wallpapers.pathFor("DP-1"));
            console.log("wallpaper HDMI-A-1: " + wallpapers.pathFor("HDMI-A-1"));
            Qt.exit(0);
        }
    }
}
