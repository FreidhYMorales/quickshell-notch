import QtQuick
import QtTest
import Quickshell

// A notch theme.json that is not valid JSON must be replaced with the default
// mode; the old shell's file is never read after the notch has state.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme }', root)

    TestCase {
        name: "ThemeBrokenState"
        when: true

        function test_broken() {
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            console.log("broken state: mode " + theme.mode + ", saved " + theme.saved);
            Qt.exit(0);
        }
    }
}
