import QtQuick
import QtTest
import Quickshell

// DP-2 is still warming on a.png when DP-1 alone switches to b.png: once the
// background work settles both monitors must hold all nine swatches.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var first: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)
    property var second: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-2" }', root)

    TestCase {
        name: "ThemeWarmupRace"
        when: true

        function count(theme, screen) {
            const own = theme.previews[screen] ?? ({});
            let n = 0;
            for (const mode in own)
                n++;
            return n;
        }

        function summary(theme, screen) {
            const own = theme.previews[screen] ?? ({});
            const colours = [];
            for (const mode in own) {
                if (colours.indexOf(own[mode].primary) === -1)
                    colours.push(own[mode].primary);
            }
            return screen + " " + count(theme, screen) + " " + colours.join(",");
        }

        function test_race() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            for (let i = 0; i < 600 && count(theme, "DP-2") < 2; i++)
                wait(20);
            console.log("at commit: DP-2 " + count(theme, "DP-2"));
            wallpapers.setApplyToAll(false);
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            for (let i = 0; i < 400; i++) {
                if (summary(theme, "DP-1") === "DP-1 9 #bbbbbb" && summary(theme, "DP-2") === "DP-2 9 #aaaaaa")
                    break;
                wait(50);
            }
            console.log("settled: " + summary(theme, "DP-1") + " | " + summary(theme, "DP-2"));
            Qt.exit(0);
        }
    }
}
