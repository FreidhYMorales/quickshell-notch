import QtQuick
import QtTest
import Quickshell

// With the apps in light, chooses a scheme and commits a shared wallpaper,
// then reads the notch's shared accents.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var config: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CONFIG_URL") + '" as Config; QtObject { property var colours: Config.Colours }', root)

    TestCase {
        name: "ThemeVariantCommits"
        when: true

        function test_commits_in_light() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            const colours = root.config.colours;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !(theme.saved && theme.applied); i++)
                wait(50);
            theme.setVariant("light");
            wait(100);
            for (let i = 0; i < 200 && (!theme.saved || !theme.applied); i++)
                wait(50);
            theme.select("scheme-vibrant");
            wait(100);
            for (let i = 0; i < 200 && (!theme.saved || !theme.applied); i++)
                wait(50);
            theme.commitWallpaper(true, "DP-1", "/w/new.png");
            wait(100);
            for (let i = 0; i < 200 && (!theme.saved || !theme.applied); i++)
                wait(50);
            wait(500);
            console.log("notch primary: " + colours.paletteFor(null).primary);
            console.log("notch global: " + colours.global.primary);
            Qt.exit(0);
        }
    }
}
