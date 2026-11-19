import QtQuick
import QtTest
import Quickshell

// Waits for the startup palette restore, then flips the app variant to light
// and lets the fake matugen and post-hook finish.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeVariant"
        when: true

        function test_variant() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 200 && !(theme.saved && theme.applied && theme.palettes["DP-1"]); i++)
                wait(50);
            theme.setVariant("light");
            wait(100);
            for (let i = 0; i < 200 && (!theme.saved || !theme.applied); i++)
                wait(50);
            console.log("theme variant: " + theme.variant);
            Qt.exit(0);
        }
    }
}
