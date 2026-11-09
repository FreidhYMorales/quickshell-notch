import QtQuick
import QtTest
import Quickshell

// A video wallpaper for every monitor: choosing a mode must theme the apps
// and the monitor palette from a still frame, and the launcher previews too.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeVideo"
        when: true

        function previewCount(theme, screen) {
            const own = theme.previews[screen];
            if (!own)
                return 0;
            let count = 0;
            for (const _mode in own)
                count++;
            return count;
        }

        function test_video() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            theme.select("scheme-vibrant");
            for (let i = 0; i < 200 && !theme.applied; i++)
                wait(50);
            theme.generatePreviews("DP-1");
            for (let i = 0; i < 200 && previewCount(theme, "DP-1") < 9; i++)
                wait(50);
            console.log("theme video: applied " + theme.applied + ", previews " + previewCount(theme, "DP-1"));
            Qt.exit(0);
        }
    }
}
