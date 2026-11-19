import QtQuick
import QtTest
import Quickshell

// Warm on a.mp4, commit b.mp4, then go back to a.mp4 while b.mp4's preview
// frame is still being extracted: a.mp4's swatches must not pick up b.mp4.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var warmup: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)

    TestCase {
        name: "ThemeWarmupVideoBack"
        when: true

        function summary(theme) {
            const own = theme.previews["DP-1"] ?? ({});
            let count = 0;
            const colours = [];
            for (const mode in own) {
                count++;
                if (colours.indexOf(own[mode].primary) === -1)
                    colours.push(own[mode].primary);
            }
            return "DP-1 " + count + " " + colours.join(",");
        }

        function settle(theme, ticks) {
            for (let i = 0; i < ticks; i++) {
                if (summary(theme).indexOf("DP-1 9 ") === 0 && !theme.previewBusy && !theme.frameBusy)
                    return;
                wait(50);
            }
        }

        function extractingB(theme) {
            const job = theme.frameJob;
            return !!job && job.role === "preview" && job.path.indexOf("b.mp4") >= 0;
        }

        function test_back() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            settle(theme, 1000);
            console.log("warm: " + summary(theme));
            wallpapers.setApplyToAll(true);
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            for (let i = 0; i < 600 && !extractingB(theme); i++)
                wait(20);
            console.log("at back: extracting b " + extractingB(theme));
            wallpapers.begin("DP-1");
            wallpapers.select(0, "DP-1");
            wallpapers.commit("DP-1");
            settle(theme, 1000);
            // A stale extraction would land after the set looked complete.
            wait(4000);
            console.log("settled: " + summary(theme));
            Qt.exit(0);
        }
    }
}
