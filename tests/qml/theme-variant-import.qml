import QtQuick
import QtTest
import Quickshell

// First start with a notch state from before the switch: waits until the
// theme service has settled and reports the variant it chose.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeVariantImport"
        when: true

        function test_import_once() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 200 && !(theme.saved && theme.applied); i++)
                wait(50);
            wait(500);
            console.log("theme variant: " + theme.variant);
            Qt.exit(0);
        }
    }
}
