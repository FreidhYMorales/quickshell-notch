import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    readonly property var items: SystemTray.items
    function hasLoadedImage(item) {
        if (item.visible && item.status !== Image.Error && item.source)
            return true;
        const children = item.children || [];
        for (let i = 0; i < children.length; i++)
            if (hasLoadedImage(children[i]))
                return true;
        return false;
    }
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            const surface = component.createObject(null, { screen: Quickshell.screens[0] });
            if (!surface || SystemTray.items.values.length !== 1 || !SystemTray.items.values[0].icon) {
                console.error("tray icon setup: no simulated icon");
                return Qt.exit(2);
            }
            surface.step({ type: "Ready" });
            surface.step({ type: "TrayHover", count: 1 });
            for (const item of surface.content) {
                if (hasLoadedImage(item)) {
                    console.log("tray icon: simulated icon is shown");
                    return Qt.exit(0);
                }
            }
            console.error("tray icon: simulated icon is not shown");
            Qt.exit(1);
        }
    }
}
