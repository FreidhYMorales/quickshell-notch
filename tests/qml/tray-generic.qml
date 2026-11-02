import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

ShellRoot {
    readonly property var items: SystemTray.items
    function hasGeneric(item) {
        if (item.visible && item.text === "?")
            return true;
        const children = item.children || [];
        for (let i = 0; i < children.length; i++)
            if (hasGeneric(children[i]))
                return true;
        return false;
    }
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
            const surface = component.createObject(null, { screen: Quickshell.screens[0] });
            if (!surface || SystemTray.items.values.length !== 1 || !SystemTray.items.values[0].icon.startsWith("image://icon/")) {
                console.error("tray generic setup: no named icon");
                return Qt.exit(2);
            }
            surface.step({ type: "Ready" });
            surface.step({ type: "TrayHover", count: 1 });
            for (const item of surface.content) {
                if (hasGeneric(item)) {
                    console.log("tray generic: fallback shown");
                    return Qt.exit(0);
                }
            }
            console.error("tray generic: fallback not shown");
            Qt.exit(1);
        }
    }
}
