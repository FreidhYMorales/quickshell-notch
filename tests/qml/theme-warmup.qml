import QtQuick
import QtTest
import Quickshell

// The shell starts on a.png and nobody opens the theme view: the warm-up for
// DP-1 must still fill all nine swatches from a.png.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme }', root)
    property var warmup: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)

    TestCase {
        name: "ThemeWarmup"
        when: true

        function test_warm() {
            const theme = root.services.theme;
            let count = 0;
            let colours = [];
            for (let i = 0; i < 200; i++) {
                const own = theme.previews["DP-1"] ?? ({});
                count = 0;
                colours = [];
                for (const mode in own) {
                    count++;
                    if (colours.indexOf(own[mode].primary) === -1)
                        colours.push(own[mode].primary);
                }
                if (count === 9)
                    break;
                wait(50);
            }
            console.log("warm: DP-1 " + count + " " + colours.join(","));
            Qt.exit(0);
        }
    }
}
