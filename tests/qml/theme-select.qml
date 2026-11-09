import QtQuick
import QtTest
import Quickshell

// Waits for the state services, chooses a scheme mode through the theme
// service and lets the fake matugen and post-hook finish.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeSelect"
        when: true

        function test_select() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            theme.select("scheme-vibrant");
            for (let i = 0; i < 100 && (!theme.saved || !theme.applied); i++)
                wait(50);
            console.log("theme mode: " + theme.mode);
            console.log("theme applied: " + theme.applied);
            Qt.exit(0);
        }
    }
}
