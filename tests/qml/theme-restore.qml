import QtQuick
import QtTest
import Quickshell

// A restart with a saved per-monitor wallpaper: the notch palette must come
// back on its own, without rerunning the app pipeline.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeRestore"
        when: true

        function test_restore() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 200; i++) {
                const palette = theme.palettes["DP-1"];
                if (theme.applied && palette)
                    break;
                wait(50);
            }
            const palette = theme.palettes["DP-1"];
            const primary = palette ? palette.primary : "none";
            console.log("palette restore: applied " + theme.applied + ", DP-1 " + primary);
            Qt.exit(0);
        }
    }
}
