pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../config"
import "../logic/controlNav.mjs" as ControlNav
import "../logic/requestQueue.mjs" as RequestQueue

// External requests from Hyprland keybinds and the power button. A request
// names an intent; which surface reacts to it is decided by the listener.
Singleton {
    id: root

    signal controlCenter(string view, string monitor)
    signal expanded(string monitor)

    // A keybind can arrive before the compositor has listed its monitors
    // (right after login). Hold every request until it does instead of
    // dropping it, keeping order and repeats.
    property var pending: []

    // `focusedMonitor` only follows focus events and can stay empty while the
    // monitor list already knows the answer.
    function focusedMonitor(): string {
        const direct = Hyprland.focusedMonitor?.name;
        if (direct)
            return direct;
        for (const monitor of Hyprland.monitors.values)
            if (monitor.focused)
                return monitor.name;
        return "";
    }

    function flush(): void {
        const monitor = focusedMonitor();
        const taken = RequestQueue.take(pending, monitor);
        if (!taken.ready.length)
            return;
        pending = taken.rest;
        for (let i = 0; i < taken.ready.length; i++) {
            const request = taken.ready[i];
            if (request.kind === "controlcenter")
                root.controlCenter(request.view, monitor);
            else
                root.expanded(monitor);
        }
    }

    function request(intent): void {
        pending = RequestQueue.enqueue(pending, intent);
        flush();
    }

    // `qs -c notch ipc call controlcenter open|notifications`.
    function openControlCenter(command: string): void {
        const view = ControlNav.commandView(command);
        if (!view) {
            console.warn("Requests: unknown control center command: " + command);
            return;
        }
        request({
            kind: "controlcenter",
            view: view
        });
    }

    // `qs -c notch ipc call expanded toggle`.
    function toggleExpanded(): void {
        request({
            kind: "expanded"
        });
    }

    Connections {
        target: Hyprland

        function onFocusedMonitorChanged() {
            root.flush();
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.pending.length > 0

        onTriggered: root.flush()
    }

    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "controlcenter"

            function open(): void {
                root.openControlCenter("open");
            }

            function notifications(): void {
                root.openControlCenter("notifications");
            }
        }
    }

    LazyLoader {
        active: !Flags.smoke

        IpcHandler {
            target: "expanded"

            function toggle(): void {
                root.toggleExpanded();
            }
        }
    }
}
