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
        name: "IdlePixelShift"
        when: true

        function test_shift() {
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
            const row = root.layer([idle], "idle-row");
            const shape = root.layer([idle], "idle-shape");
            if (!row || !shape)
                return Qt.exit(4);
            // Where the content and the black shape sit inside the idle layer.
            const at = item => item.mapToItem(idle, 0, 0);
            const outline = () => {
                const p = at(shape);
                return p.x + "," + p.y + " " + shape.width + "x" + shape.height;
            };
            const home = at(row);
            const shapeHome = outline();
            const moved = () => {
                const p = at(row);
                return Math.round(p.x - home.x) + "," + Math.round(p.y - home.y);
            };
            const shapeNow = () => outline() === shapeHome ? "shape same" : "shape " + outline() + " was " + shapeHome;
            idle.shiftStep = 2;
            wait(100);
            const two = moved() + " " + shapeNow();
            idle.shiftStep = 3;
            wait(100);
            const three = moved() + " " + shapeNow();
            // The expanded view is never shifted: its clock sits in the same
            // place at step 0 and step 1.
            idle.shiftStep = 0;
            root.center.store.dispatch({
                type: "Hover",
                monitor: screen.name,
                on: true
            });
            wait(800);
            const clock = root.layer([expanded], "calendar-clock");
            if (!clock)
                return Qt.exit(5);
            const before = clock.mapToItem(expanded, 0, 0);
            idle.shiftStep = 1;
            wait(100);
            const after = clock.mapToItem(expanded, 0, 0);
            const still = before.x === after.x && before.y === after.y ? "same" : "moved " + (after.x - before.x) + "," + (after.y - before.y);
            root.center.store.dispatch({
                type: "Hover",
                monitor: screen.name,
                on: false
            });
            wait(800);
            console.log("pixel shift: step2 " + two + "; step3 " + three + "; expanded " + still + "; back " + moved());
            Qt.exit(0);
        }
    }
}
