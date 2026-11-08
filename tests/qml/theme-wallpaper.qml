import QtQuick
import QtTest
import Quickshell

// Commits the second wallpaper entry (b.png) for DP-1 through the wallpaper
// service, shared or as a per-monitor override, and waits for the theme.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeWallpaper"
        when: true

        function test_commit() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && wallpapers.entries.length === 0; i++)
                wait(50);
            wallpapers.setApplyToAll(Quickshell.env("THEME_PROBE_SHARED") === "1");
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            for (let i = 0; i < 100 && !theme.applied; i++)
                wait(50);
            console.log("theme commit applied: " + theme.applied);
            console.log("theme commit path: " + wallpapers.pathFor("DP-1"));
            Qt.exit(0);
        }
    }
}
