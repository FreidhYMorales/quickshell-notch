import QtQuick
import QtTest
import Quickshell

// Announces a window move from workspace 1 to 3 on the workspaces notch and
// reads where the flying icon is mid-flight and whether it is gone after.
ShellRoot {
    id: root
    property var services: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_SERVICES_URL") + '" as Services; QtObject { property var workspaces: Services.Workspaces }', root)

    // Walks every child, visible or not.
    function named(items, name) {
        for (let i = 0; i < items.length; i++) {
            if (items[i].objectName === name)
                return items[i];
            const kids = items[i].children;
            const nested = kids && typeof kids.length === "number" ? root.named(kids, name) : null;
            if (nested)
                return nested;
        }
        return null;
    }

    TestCase {
        name: "WorkspacesFlyRelayout"
        when: true

        function test_relayout() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_WORKSPACES_URL") + "/WorkspacesSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            const ws = root.services.workspaces;
            const kitty = workspace => ({
                    address: "0x1",
                    cls: "kitty",
                    workspaceId: workspace,
                    monitor: screen.name,
                    focus: 0,
                    mapped: true,
                    hidden: false,
                    floating: false
                });
            // A real move: the service's windows change in the same tick as
            // the event, so the strip (and every slot) is rebuilt with it.
            const monitors = {};
            monitors[screen.name] = {
                activeId: 2
            };
            ws.snapshot = {
                monitors: monitors,
                windows: []
            };
            ws.normalWindows = [kitty(1)];
            // Past the startup gate, so the move reveals the strip.
            wait(1300);
            ws.normalWindows = [kitty(3)];
            ws.triggered(screen.name, [
                {
                    kind: "move",
                    workspaceId: 3,
                    cls: "kitty",
                    from: 1
                }
            ]);
            wait(30);
            const one = root.named(surface.content, "ws-slot-1");
            const three = root.named(surface.content, "ws-slot-3");
            const flyer = root.named(surface.content, "ws-flyer");
            if (!one || !three)
                return Qt.exit(3);
            const centre = item => item.mapToItem(null, item.width / 2, 0).x;
            let start = "missing";
            if (flyer && flyer.visible) {
                const off = Math.round(centre(flyer) - centre(one));
                start = Math.abs(off) <= 3 ? "at source" : "off source by " + off;
            }
            const empty = three.opacity < 0.01 ? "destination empty" : "destination shown during flight";
            wait(700);
            const landed = root.named(surface.content, "ws-slot-3");
            const after = (flyer && flyer.visible ? "still shown" : "gone") + ", " + (landed && landed.opacity > 0.99 ? "destination shown" : "destination still empty");
            console.log("workspaces relayout: start " + start + "; " + empty + "; after " + after);
            Qt.exit(0);
        }
    }
}
