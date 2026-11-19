import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Scrolls the week strip forward and back, then opens the month, scrolls it and
// jumps back to today with the title, reading the centre day and the title.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "CalendarScroll"
        when: true

        function test_scroll_and_today() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);
            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                screen: screen
            });
            // A real notification arriving mid-probe would show as a toast
            // over the expanded notch: mute them, and dismiss a critical one
            // already up (the low-battery warning shows at startup).
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
            root.center.store.dispatch({
                type: "Hover",
                monitor: screen.name,
                on: true
            });
            wait(800);
            const named = name => Visual.findNamed(surface.content, name);
            const centre = () => named("calendar-centre") ? named("calendar-centre").text : "none";
            const title = () => named("calendar-title") ? named("calendar-title").text : "none";
            // QtTest's synthetic wheel never reaches this layer-shell surface,
            // so the probe calls the function the WheelHandler calls; the real
            // wheel is part of the manual check.
            const scroll = (name, dy) => {
                const item = named(name);
                if (item)
                    item.scroll(dy);
                wait(400);
            };
            const click = name => {
                const item = named(name);
                if (item)
                    mouseClick(item);
                wait(400);
            };
            const start = centre();
            scroll("calendar-card", -120);
            const nextWeek = centre();
            // Scrolling back up returns the strip to today.
            scroll("calendar-card", 120);
            const backWeek = centre();
            click("calendar-week");
            scroll("calendar-month-view", -120);
            const nextMonth = title();
            click("calendar-title");
            const backMonth = title();
            console.log("calendar scroll: week " + start + " > " + nextWeek + " > " + backWeek + "; month " + nextMonth + " > " + backMonth);
            Qt.exit(0);
        }
    }
}
