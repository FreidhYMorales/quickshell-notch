import QtQuick
import QtTest
import Quickshell

// DP-1 and DP-2 start warm on a.png. A commit to b.png (shared or for DP-1
// only, per NOTCH_SHARED) must leave each monitor warm on its own wallpaper
// without anyone opening the theme view.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var first: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)
    property var second: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-2" }', root)

    TestCase {
        name: "ThemeWarmupCommit"
        when: true

        function summary(theme, screen) {
            const own = theme.previews[screen] ?? ({});
            let count = 0;
            const colours = [];
            for (const mode in own) {
                count++;
                if (colours.indexOf(own[mode].primary) === -1)
                    colours.push(own[mode].primary);
            }
            return screen + " " + count + " " + colours.join(",");
        }

        function settle(theme, expected) {
            for (let i = 0; i < 300; i++) {
                if (summary(theme, "DP-1") === expected[0] && summary(theme, "DP-2") === expected[1])
                    return;
                wait(50);
            }
        }

        function test_commit() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            settle(theme, ["DP-1 9 #aaaaaa", "DP-2 9 #aaaaaa"]);
            console.log("before: " + summary(theme, "DP-1") + " | " + summary(theme, "DP-2"));
            const shared = Quickshell.env("NOTCH_SHARED") === "1";
            wallpapers.setApplyToAll(shared);
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            settle(theme, ["DP-1 9 #bbbbbb", shared ? "DP-2 9 #bbbbbb" : "DP-2 9 #aaaaaa"]);
            console.log("after: " + summary(theme, "DP-1") + " | " + summary(theme, "DP-2"));
            Qt.exit(0);
        }
    }
}
