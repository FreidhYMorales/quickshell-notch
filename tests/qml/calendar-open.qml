import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Expands the centre notch, clicks the clock card to open the month and Esc to
// leave it, reading the notch height and what shows each time.
ShellRoot {
    id: root
    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    TestCase {
        name: "CalendarOpen"
        when: true

        function test_open_and_back() {
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
            const describe = () => {
                const title = Visual.findNamed(surface.content, "calendar-title");
                const strip = Visual.findNamed(surface.content, "calendar-week");
                return surface.size.height + " " + (title ? title.text : "no-title") + " " + (strip ? "strip" : "no-strip");
            };
            const before = describe();
            // The whole card opens the month: click its clock, not the strip.
            const clock = Visual.findNamed(surface.content, "calendar-clock");
            if (clock)
                mouseClick(clock);
            wait(800);
            const opened = describe() + " " + (Visual.findNamed(surface.content, "calendar-back") ? "close" : "no-close");
            // Esc is the only way back.
            keyClick(Qt.Key_Escape);
            wait(800);
            const closed = describe();
            console.log("calendar open: before " + before + "; opened " + opened + "; back " + closed);
            Qt.exit(0);
        }
    }
}
