import QtQuick
import QtTest
import Quickshell

// Hovers the idle centre notch and reads the idle and expanded layers'
// opacity mid-morph and once the morph has settled.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    // Walks every child, visible or not: a faded layer is still there.
    function layer(items, name) {
        for (let i = 0; i < items.length; i++) {
            if (items[i].objectName === name)
                return items[i];
            const kids = items[i].children;
            const nested = kids && typeof kids.length === "number" ? root.layer(kids, name) : null;
            if (nested)
                return nested;
        }
        return null;
    }

    TestCase {
        name: "ExpandedCrossfadeOpen"
        when: true

        function test_open() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "Dnd",
                on: true
            });
            wait(300);
            const shown = root.center.store.state.global.toast;
            if (shown)
                root.center.store.dispatch({
                    type: "ToastDismissed",
                    id: shown.id
                });
            wait(300);
            const idle = root.layer(surface.content, "center-idle");
            const expanded = root.layer(surface.content, "center-expanded");
            if (!idle || !expanded)
                return Qt.exit(3);
            const fmt = v => Math.round(v * 100) / 100;
            const state = () => (idle.visible ? "shown" : "hidden") + " " + (expanded.visible ? "shown" : "hidden");
            root.center.store.dispatch({
                type: "Hover",
                monitor: screen.name,
                on: true
            });
            wait(60);
            const mid = idle.opacity > 0 && idle.opacity < 1 && expanded.opacity > 0 && expanded.opacity < 1 ? "both partial" : "idle " + fmt(idle.opacity) + " expanded " + fmt(expanded.opacity);
            wait(800);
            console.log("crossfade open: mid " + mid + "; settled idle " + fmt(idle.opacity) + " expanded " + fmt(expanded.opacity) + " " + state());
            Qt.exit(0);
        }
    }
}
