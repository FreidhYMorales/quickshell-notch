import QtQuick
import QtTest
import Quickshell
import "visual.mjs" as Visual

// Opens the month directly, then uses Esc to return to the media controls and
// a second Esc to close the notch.
ShellRoot {
    id: root

    property var center: Qt.createQmlObject('import QtQuick; import "' + Quickshell.env("NOTCH_CENTER_URL") + '" as Center; QtObject { property var store: Center.CenterStore }', root)

    PanelWindow {
        implicitWidth: 1
        implicitHeight: 1
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent
        }

    }

    TestCase {
        function test_open_and_back() {
            const component = Qt.createComponent(Quickshell.env("NOTCH_CENTER_URL") + "/CenterSurface.qml");
            if (component.status !== Component.Ready || Quickshell.screens.length === 0)
                return Qt.exit(2);

            const screen = Quickshell.screens[0];
            const surface = component.createObject(null, {
                "screen": screen
            });
            // A real notification arriving mid-probe would show as a toast
            // over the expanded notch: mute them, and dismiss a critical one
            // already up (the low-battery warning shows at startup).
            root.center.store.dispatch({
                "type": "Dnd",
                "on": true
            });
            wait(300);
            const shown = root.center.store.state.global.toast;
            if (shown)
                root.center.store.dispatch({
                "type": "ToastDismissed",
                "id": shown.id
            });

            root.center.store.dispatch({
                "type": "CalendarToggle",
                "monitor": screen.name
            });
            wait(800);
            const describe = () => {
                const title = Visual.findNamed(surface.content, "calendar-title");
                const strip = Visual.findNamed(surface.content, "calendar-week");
                return surface.size.height + " " + (title ? title.text : "no-title") + " " + (strip ? "strip" : "no-strip");
            };
            const opened = describe();
            keyClick(Qt.Key_Escape);
            wait(800);
            const closed = describe();
            const afterBack = root.center.store.state.monitors[screen.name];
            const afterBackView = root.center.store.viewFor(screen.name);
            const previous = Visual.findNamed(surface.content, "media-prev");
            const playPause = Visual.findNamed(surface.content, "media-play-pause");
            const mediaFocused = (!previous && !playPause) || (previous && previous.enabled ? previous.activeFocus : playPause && playPause.activeFocus);
            keyClick(Qt.Key_Escape);
            wait(300);
            const afterClose = root.center.store.state.monitors[screen.name];
            console.log("calendar open: direct " + opened + "; back " + closed + "; pinned after back " + afterBack.pinned + "; keyboard focus " + afterBackView.keyboardFocus + "; media focus " + mediaFocused + "; pinned after close " + afterClose.pinned + "; keyboard focus after close " + afterClose.keyboardFocus);
            Qt.exit(0);
        }

        name: "CalendarOpen"
        when: true
    }

}
