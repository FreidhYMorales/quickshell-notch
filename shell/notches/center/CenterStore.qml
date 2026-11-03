pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Polkit
import QtQuick
import "../../config"
import "../../services"
import "../../logic/sideLayer.mjs" as SideLayer
import "../../logic/centerState.mjs" as CenterState
import "../../logic/centerView.mjs" as CenterView
import "../../logic/notifQueue.mjs" as NotifQueue
import "../../logic/powerMenu.mjs" as PowerMenu

// The one global holder of the centre reducer state. Surfaces send events with
// `dispatch` and read `viewFor(screenName)`; effects are executed here.
// Other event sources (launcher, polkit) arrive in later phases.
Singleton {
    id: root

    property var state: CenterState.initialState(screenNames())
    // Id of the notification the reducer currently shows as a toast (null: none).
    property var toastId: null

    LazyLoader {
        active: !Flags.smoke

        PolkitAgent {
            id: polkitAgent

            onFlowChanged: {
                if (polkitAgent.flow)
                    root.dispatch({
                        type: "PolkitRequest",
                        flowId: polkitAgent.flow,
                        monitor: Hyprland.focusedMonitor?.name
                    });
            }
        }
    }

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
        if (effect.type === "app.launch") {
            Apps.launch(effect.appId);
            return;
        }
        if (effect.type === "power.run") {
            Power.run(effect.action);
            return;
        }
        if (effect.type === "polkit.cancel") {
            effect.flowId.cancelAuthenticationRequest();
            return;
        }
        console.log("CenterStore: effect (no service yet): " + JSON.stringify(effect));
    }

    // Mirrors the head of the notification queue into the reducer. A critical
    // one muted on arrival (indicator phase) goes straight to the pins.
    function syncToast() {
        const current = Notifs.current;
        if (!NotifQueue.headChanged(toastId, current))
            return;
        const id = current ? current.id : null;
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

    // Opens the power menu on the focused monitor, optionally preselecting an
    // action (unknown names preselect nothing).
    function toggleLauncher() {
        const monitor = Hyprland.focusedMonitor?.name;
        if (!monitor) {
            console.warn("CenterStore: no focused monitor for the launcher");
            return;
        }
        dispatch({
            type: "LauncherToggle",
            monitor: monitor
        });
    }

    function openPower(action) {
        const monitor = Hyprland.focusedMonitor?.name;
        if (!monitor) {
            console.warn("CenterStore: no focused monitor for the power menu");
            return;
        }
        dispatch({
            type: "PowerOpen",
            monitor: monitor,
            action: PowerMenu.ACTIONS.includes(action) ? action : null
        });
    }

    // `qs -c notch ipc call launcher toggle` (the launcher keybind).
    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "launcher"

            function toggle(): void {
                root.toggleLauncher();
            }
        }
    }

    // `qs -c notch ipc call power open` (Ctrl+Alt+Del) or `openAt <action>`.
    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "power"

            function open(): void {
                root.openPower(null);
            }

            function openAt(action: string): void {
                root.openPower(action);
            }
        }
    }

    // The power menu hold: started once per hold (repeats keep the same state,
    // so the timer is not restarted); releasing early stops it.
    Timer {
        interval: Timings.holdConfirm
        running: root.state.global.keyboard?.hold != null
        onTriggered: root.dispatch({
            type: "HoldComplete"
        })
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
