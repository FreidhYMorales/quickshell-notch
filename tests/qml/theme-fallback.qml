import QtQuick
import QtTest
import Quickshell

// Prints the three colours the notch uses when no matugen palette exists.
ShellRoot {
    id: root
    property var config: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CONFIG_URL") + '" as Config; QtObject { property var colours: Config.Colours }', root)

    TestCase {
        name: "ThemeFallback"
        when: true

        function test_fallback() {
            const fallback = root.config.colours.fallback;
            console.log("fallback: " + fallback.primary + " " + fallback.onSurface + " " + fallback.muted);
            Qt.exit(0);
        }
    }
}
