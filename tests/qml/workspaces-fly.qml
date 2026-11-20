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
        name: "WorkspacesFly"
        when: true

        function test_fly() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_WORKSPACES_URL") + "/WorkspacesSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            // Past the startup gate, so the move reveals the strip.
            wait(1300);
            root.services.workspaces.triggered(screen.name, [
                {
                    kind: "move",
                    workspaceId: 3,
                    cls: "kitty",
                    from: 1
                }
            ]);
            wait(150);
            const one = root.named(surface.content, "ws-slot-1");
            const three = root.named(surface.content, "ws-slot-3");
            const flyer = root.named(surface.content, "ws-flyer");
            if (!one || !three)
                return Qt.exit(3);
            const centre = item => item.mapToItem(null, item.width / 2, 0).x;
            let mid = "missing";
            if (flyer && flyer.visible) {
                const x = centre(flyer);
                mid = x > centre(one) && x < centre(three) ? "between" : "at " + Math.round(x) + " not in " + Math.round(centre(one)) + ".." + Math.round(centre(three));
            }
            wait(700);
            const after = flyer && flyer.visible ? "still shown" : "gone";
            console.log("workspaces fly: mid " + mid + "; after " + after);
            Qt.exit(0);
        }
    }
}
