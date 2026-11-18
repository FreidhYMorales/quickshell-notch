import QtQuick
import Quickshell

// The image each lock surface paints during the screensaver: the chosen
// wallpaper while "Same as desktop wallpaper" is off, the monitor's own
// otherwise. Runs under smoke, so no session lock is ever requested.
ShellRoot {
    id: root
    property var lock: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var idle: Services.Idle; property var wallpapers: Services.Wallpapers }', root)

    Component.onCompleted: check.start()

    Timer {
        id: check
        interval: 100
        onTriggered: {
            root.lock = Qt.createQmlObject('import "' + Quickshell.env("NOTCH_LOCK_URL") + '"; Lock {}', root);
            const idle = root.services.idle;
            root.services.wallpapers.fallback = "/w/desk.png";
            idle.choice = {
                sameAsDesktop: false,
                path: "/w/chosen.png"
            };
            const chosen = root.lock.screensaverPathFor("DP-1");
            idle.choice = {
                sameAsDesktop: true,
                path: "/w/chosen.png"
            };
            const same = root.lock.screensaverPathFor("DP-1");
            console.log("lock screensaver image: off " + chosen + ", on " + same);
            Qt.exit(0);
        }
    }
}
