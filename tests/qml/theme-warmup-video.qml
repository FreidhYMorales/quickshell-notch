import QtQuick
import QtTest
import Quickshell

// The warm-up is still extracting a.mp4's frame when a shared commit switches
// to b.mp4: once everything settles no swatch may keep a.mp4's colour.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)
    property var warmup: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_COMPONENTS_URL") + '" as Components; Components.ThemeWarmup { monitorName: "DP-1" }', root)

    TestCase {
        name: "ThemeWarmupVideo"
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

        function test_video() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            for (let i = 0; i < 200 && !theme.frameBusy; i++)
                wait(20);
            console.log("at commit: extracting " + theme.frameBusy);
            wallpapers.setApplyToAll(true);
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            for (let i = 0; i < 400; i++) {
                if (summary(theme).indexOf("DP-1 9 ") === 0 && !theme.previewBusy && !theme.frameBusy)
                    break;
                wait(50);
            }
            // A stale extraction would land after the set looked complete.
            wait(3000);
            console.log("settled: " + summary(theme));
            Qt.exit(0);
        }
    }
}
