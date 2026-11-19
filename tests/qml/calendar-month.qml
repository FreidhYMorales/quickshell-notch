import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Expands the centre notch, opens the month through the store and reads the
// notch height and the month view: title, grid size and today's cell.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    function countNamed(items, name) {
        let count = 0;
        for (const item of items) {
            if (item.visible && item.objectName === name)
                count += 1;
            const children = item.children;
            if (children && typeof children.length === "number")
                count += countNamed(children, name);
        }
        return count;
    }

    TestCase {
        name: "CalendarMonth"
        when: true

        function test_month() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            root.center.store.dispatch({
                type: "Hover",
                monitor: screen.name,
                on: true
            });
            wait(800);
            const week = surface.size.height;
            root.center.store.dispatch({
                type: "CalendarMonth",
                monitor: screen.name
            });
            wait(800);
            const month = surface.size.height;
            const title = Visual.findNamed(surface.content, "calendar-title");
            const today = Visual.findNamed(surface.content, "calendar-today");
            const days = root.countNamed(surface.content, "calendar-day") + root.countNamed(surface.content, "calendar-today");
            const media = Visual.findNamed(surface.content, "calendar-week");
            console.log("calendar month: week " + week + ", month " + month + ", title " + (title ? title.text : "none") + ", days " + days + ", today " + (today ? today.text : "none") + ", week strip " + (media !== null));
            Qt.exit(0);
        }
    }
}
