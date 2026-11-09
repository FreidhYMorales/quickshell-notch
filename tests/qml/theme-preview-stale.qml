import QtQuick
import QtTest
import Quickshell

// Previews are being computed against a.png when a shared commit switches the
// wallpaper to b.png: the palettes still in flight must not be stored.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var theme: Services.Theme; property var wallpapers: Services.Wallpapers }', root)

    TestCase {
        name: "ThemePreviewStale"
        when: true

        function stalePreviews(theme) {
            const own = theme.previews["DP-1"] ?? ({});
            let stale = 0;
            for (const mode in own) {
                if (own[mode].primary === "#aaaaaa")
                    stale++;
            }
            return stale;
        }

        function test_stale() {
            const wallpapers = root.services.wallpapers;
            const theme = root.services.theme;
            for (let i = 0; i < 100 && !wallpapers.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && !theme.saved; i++)
                wait(50);
            for (let i = 0; i < 100 && wallpapers.entries.length < 2; i++)
                wait(50);
            theme.generatePreviews("DP-1");
            wait(400);
            wallpapers.setApplyToAll(true);
            wallpapers.begin("DP-1");
            wallpapers.select(wallpapers.entries.length - 1, "DP-1");
            wallpapers.commit("DP-1");
            for (let i = 0; i < 200 && !theme.applied; i++)
                wait(50);
            wait(500);
            console.log("after commit: stale " + stalePreviews(theme));
            theme.generatePreviews("DP-1");
            for (let i = 0; i < 200; i++) {
                const own = theme.previews["DP-1"] ?? ({});
                let count = 0;
                let primary = "";
                for (const mode in own) {
                    count++;
                    primary = own[mode].primary;
                }
                if (count === 9 && primary === "#bbbbbb")
                    break;
                wait(50);
            }
            const own = theme.previews["DP-1"] ?? ({});
            const first = own["scheme-content"];
            console.log("after regen: DP-1 " + (first ? first.primary : "none"));
            Qt.exit(0);
        }
    }
}
