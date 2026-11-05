pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../config"
import "../logic/controlNav.mjs" as ControlNav

// External requests from Hyprland keybinds and the power button. A request
// names an intent; which surface reacts to it is decided by the listener.
Singleton {
    id: root

    signal controlCenter(string view, string monitor)
    signal expanded(string monitor)

    // A keybind can arrive before the compositor has listed its monitors
    // (right after login). Hold the request until it does instead of dropping
    // it.
    property string pendingView: ""
    property bool pendingExpanded: false

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
        if (!pendingView && !pendingExpanded)
            return;
        const monitor = focusedMonitor();
        if (!monitor)
            return;
        const view = pendingView;
        const expand = pendingExpanded;
        pendingView = "";
        pendingExpanded = false;
        if (view)
            root.controlCenter(view, monitor);
        if (expand)
            root.expanded(monitor);
    }

    // `qs -c notch ipc call controlcenter open|notifications`.
    function openControlCenter(command: string): void {
        const view = ControlNav.commandView(command);
        if (!view) {
            console.warn("Requests: unknown control center command: " + command);
            return;
        }
        pendingView = view;
        flush();
    }

    // `qs -c notch ipc call expanded toggle`.
    function toggleExpanded(): void {
        pendingExpanded = true;
        flush();
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
        running: root.pendingView !== "" || root.pendingExpanded

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
