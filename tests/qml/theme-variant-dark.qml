import QtQuick
import QtTest
import Quickshell

// Flips the apps to light and back to dark, then reads the notch's shared
// accents once the dark colors.json has landed.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var config: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CONFIG_URL") + '" as Config; QtObject { property var colours: Config.Colours }', root)

    TestCase {
        name: "ThemeVariantDark"
        when: true

        function test_back_to_dark() {
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
            theme.setVariant("dark");
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
