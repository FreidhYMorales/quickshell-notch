import QtQuick
import QtTest
import Quickshell

// Chooses two modes back to back while the first matugen run is still slow,
// or chooses one mode when no wallpaper exists at all.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeAppQueue"
        when: true

        function test_queue() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            theme.select("scheme-vibrant");
            wait(100);
            theme.select("scheme-neutral");
            for (let i = 0; i < 200 && !theme.applied; i++)
                wait(50);
            console.log("app queue: applied " + theme.applied + ", mode " + theme.mode);
            Qt.exit(0);
        }
    }
}
