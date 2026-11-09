import QtQuick
import QtTest
import Quickshell

// Selects a mode with no matugen anywhere on PATH. Both the app pipeline and
// the per-monitor palette queue must recover instead of staying busy forever.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemeMissingMatugen"
        when: true

        function test_missing() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            theme.select("scheme-vibrant");
            for (let i = 0; i < 100 && !theme.applied; i++)
                wait(50);
            const idle = !theme.paletteBusy && theme.paletteQueue.length === 0;
            console.log("missing matugen: applied " + theme.applied + ", queues " + (idle ? "idle" : "busy"));
            Qt.exit(0);
        }
    }
}
