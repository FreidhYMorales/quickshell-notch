pragma Singleton

import Quickshell
import QtQuick
import "../../config"
import "../../services"
import "../../logic/sideLayer.mjs" as SideLayer
import "../../logic/centerState.mjs" as CenterState
import "../../logic/centerView.mjs" as CenterView

// The one global holder of the centre reducer state. Surfaces send events with
// `dispatch` and read `viewFor(screenName)`; effects are executed here.
// Other event sources (launcher, polkit) arrive in later phases.
Singleton {
    id: root

    property var state: CenterState.initialState(screenNames())
    // Id of the notification the reducer currently shows as a toast (-1: none).
    property int toastId: -1

    // What the idle notch shows in its side slots: low > media > battery.
    readonly property string sideLayer: SideLayer.sideLayer(Battery.layer, Mpris.playing)

    function screenNames(): var {
        const names = [];
        for (let i = 0; i < Quickshell.screens.length; i++)
            names.push(Quickshell.screens[i].name);
        return names;
    }

    // The unread dot is the same on every monitor.
    readonly property var unreadDot: CenterView.unreadDot(state, Notifs.unread)

    function viewFor(name: string): var {
        return CenterView.viewFor(state, name);
    }

    function dispatch(event) {
        const result = CenterState.reduce(state, event);
        state = result.state;
        for (let i = 0; i < result.effects.length; i++)
            run(result.effects[i]);
    }

    // Effects whose services do not exist yet are logged only.
    function run(effect) {
        if (effect.type === "toast.skip" && effect.id === Notifs.current?.id) {
            Notifs.advance();
            return;
        }
        console.log("CenterStore: effect (no service yet): " + JSON.stringify(effect));
    }

    // Mirrors the head of the notification queue into the reducer. A critical
    // one muted on arrival (indicator phase) goes straight to the pins.
    function syncToast() {
        const current = Notifs.current;
        const id = current ? current.id : -1;
        if (id === toastId)
            return;
        const previous = toastId;
        toastId = id;
        if (current) {
            dispatch({
                type: "ToastShown",
                id: id,
                critical: Notifs.currentCritical
            });
            if (state.global.toast?.phase === "indicator") {
                Notifs.collapse();
                return;
            }
            if (toastTimer.running)
                toastTimer.restart();
        } else {
            dispatch({
                type: "ToastDismissed",
                id: previous
            });
        }
    }

    // One global toast timer; a hover on any monitor pauses it.
    Timer {
        id: toastTimer

        interval: Timings.toast
        running: root.state.global.toast?.phase === "shown" && !CenterView.toastPaused(root.state)
        onTriggered: {
            root.dispatch({
                type: "ToastTimeout",
                id: root.toastId
            });
            Notifs.collapse();
        }
    }

    Connections {
        function onCurrentChanged() {
            root.syncToast();
        }

        function onDndChanged() {
            root.dispatch({
                type: "Dnd",
                on: Notifs.dnd
            });
        }

        target: Notifs
    }

    // cava runs only while the media layer shows.
    Binding {
        target: Cava
        property: "wanted"
        value: root.sideLayer === "media"
    }

    Connections {
        function onScreensChanged() {
            root.dispatch({
                type: "ScreensChanged",
                names: root.screenNames()
            });
        }

        target: Quickshell
    }

    Connections {
        function onLockedChanged() {
            root.dispatch({
                type: "Locked",
                on: Session.locked
            });
        }

        target: Session
    }

    // The battery's one-shot critical event becomes a critical toast.
    function postBatteryCritical() {
        Notifs.post(Strings.batteryCriticalApp, Strings.batteryCriticalSummary, Strings.batteryCriticalBody.arg(Battery.percentage), Strings.batteryCriticalIcon);
    }

    // Already fired before this store connected (shell start at <= critical).
    Component.onCompleted: {
        if (!Battery.armed)
            postBatteryCritical();
    }

    Connections {
        function onCriticalReached() {
            root.postBatteryCritical();
        }

        target: Battery
    }
}
