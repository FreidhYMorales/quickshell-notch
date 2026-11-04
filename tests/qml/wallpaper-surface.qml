import QtQuick
import Quickshell
import "visual.mjs" as Visual

ShellRoot {
    id: root
    property var target: null
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var wallpapers: Services.Wallpapers }', root)
    Timer {
        interval: 500
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            if (component.status !== Component.Ready || Quickshell.screens.length === 0) {
                console.error("wallpaper surface: " + component.errorString());
                return Qt.exit(2);
            }
            const screen = Quickshell.screens[0];
            const perScreen = {};
            perScreen[screen.name] = "/w/own.png";
            root.services.wallpapers.fallback = "/w/other.png";
            root.services.wallpapers.perScreen = perScreen;
            root.target = component.createObject(null, {
                screen: screen
            });
            check.start();
        }
    }
    Timer {
        id: check
        interval: 500
        onTriggered: {
            if (!Visual.findImage(root.target.contentItem.children, "file:///w/own.png")) {
                console.error("wallpaper surface: own wallpaper missing");
                return Qt.exit(1);
            }
            console.log("wallpaper surface: own wallpaper shown");
            Qt.exit(0);
        }
    }
}
