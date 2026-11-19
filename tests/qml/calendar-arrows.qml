import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the month and pages it with the header arrows, reading the title.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "CalendarArrows"
        when: true

        function test_arrows() {
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
            const scroll = name => {
                const item = named(name);
                if (item)
                    item.scroll(-120);
                wait(400);
            };
            const click = name => {
                const item = named(name);
                if (item)
                    mouseClick(item);
                wait(400);
            };
            click("calendar-week");
            const opened = title();
            click("calendar-next");
            const next = title();
            click("calendar-prev");
            click("calendar-prev");
            const previous = title();
            console.log("calendar arrows: " + opened + " > " + next + " > " + previous);
            Qt.exit(0);
        }
    }
}
