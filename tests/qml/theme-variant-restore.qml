import QtQuick
import QtTest
import Quickshell

// A restart with light apps saved: reads the notch's shared accents once the
// startup restore is done, without touching the variant.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var config: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CONFIG_URL") + '" as Config; QtObject { property var colours: Config.Colours }', root)

    TestCase {
        name: "ThemeVariantRestore"
        when: true

        function test_restore_light() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            const colours = root.config.colours;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 200 && !(theme.applied && colours.shared); i++)
                wait(50);
            wait(500);
            console.log("theme variant: " + theme.variant);
            console.log("notch primary: " + colours.paletteFor(null).primary);
            console.log("notch global: " + colours.global.primary);
            Qt.exit(0);
        }
    }
}
