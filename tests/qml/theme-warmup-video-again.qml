import QtQuick
import QtTest
import Quickshell

// While a.mp4's frame is extracting, DP-1 goes to b.mp4 and back to a.mp4,
// then commits a.mp4 again once b.mp4's frame is extracting: a.mp4's
// swatches must never read b.mp4's frame.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var warmup: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)

    TestCase {
        name: "ThemeWarmupVideoAgain"
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

        function extracting(theme, name) {
            const job = theme.frameJob;
            return !!job && job.role === "preview" && job.path.indexOf(name) >= 0;
        }

        function commitTo(wallpapers, index) {
            wallpapers.begin("DP-1");
            wallpapers.select(index, "DP-1");
            wallpapers.commit("DP-1");
        }

        function test_again() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            wallpapers.setApplyToAll(false);
            for (let i = 0; i < 600 && !extracting(theme, "a.mp4"); i++)
                wait(20);
            console.log("first a extracting " + extracting(theme, "a.mp4"));
            commitTo(wallpapers, wallpapers.entries.length - 1);
            wait(50);
            commitTo(wallpapers, 0);
            wait(50);
            for (let i = 0; i < 1000 && !extracting(theme, "b.mp4"); i++)
                wait(20);
            console.log("b extracting " + extracting(theme, "b.mp4"));
            commitTo(wallpapers, 0);
            settle(theme, 1000);
            // A stale extraction would land after the set looked complete.
            wait(8000);
            settle(theme, 1000);
            console.log("settled: " + summary(theme));
            Qt.exit(0);
        }
    }
}
