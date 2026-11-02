import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Timer {
    id: root
    property var target: null
    readonly property var items: SystemTray.items
    interval: 3000
    running: true
    onTriggered: {
        const component = Qt.createComponent(Quickshell.env("NOTCH_TEST_SURFACE"));
        if (component.status !== Component.Ready || items.values.length !== 1 || !items.values[0].hasMenu)
            return Qt.exit(2);
        target = component.createObject(null, { screen: Quickshell.screens[0] });
        target.step({ type: "Ready" });
        target.step({ type: "TrayHover", count: 1 });
    }
}
