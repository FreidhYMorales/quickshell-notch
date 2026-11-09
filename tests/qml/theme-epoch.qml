import QtQuick
import QtTest
import Quickshell

// The startup palette for a per-monitor override is still being computed when
// a shared wallpaper commit clears every override; its result must be dropped.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeEpoch"
        when: true

        function test_epoch() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            wait(100);
            theme.commitWallpaper(true, "DP-1", "/w/new.png");
            for (let i = 0; i < 200 && !theme.applied; i++)
                wait(50);
            wait(600);
            const palette = theme.palettes["DP-1"];
            console.log("shared commit: applied " + theme.applied + ", DP-1 palette " + (palette ? palette.primary : "none"));
            Qt.exit(0);
        }
    }
}
