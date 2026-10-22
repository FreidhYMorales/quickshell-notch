pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../logic/workspaceStrip.mjs" as Strip

// Normalises Hyprland into a per-monitor snapshot. Raw events refresh the
// toplevels and arm one debounce timer; the snapshot is rebuilt once, diffed
// against the previous one and the result is announced per monitor. Special
// workspaces come from the raw event `activespecial` (never `active`).
// Inert under Flags.smoke.
Singleton {
    id: root

    readonly property var rules: ({
            minFloatWidth: Limits.floatMinWidth,
            minFloatHeight: Limits.floatMinHeight
        })
    // { monitors: { [name]: { activeId } }, windows: [Win] }
    property var snapshot: ({
            monitors: {},
            windows: []
        })
    // Only windows that count for occupancy, icons and triggers.
    property var normalWindows: []
    // Active special workspace name per monitor ("" when none).
    property var specialByMonitor: ({})
    property bool primed: false

    signal triggered(string monitor, var events)

    function build(): var {
        const monitors = {};
        for (const m of Hyprland.monitors.values)
            monitors[m.name] = {
                activeId: m.activeWorkspace?.id ?? 0
            };
        const windows = [];
        for (const t of Hyprland.toplevels.values) {
            const w = Strip.windowFrom(t.lastIpcObject, {
                monitor: t.monitor?.name ?? "",
                hasParent: !!t.wayland?.parent
            });
            if (w)
                windows.push(w);
        }
        return {
            monitors: monitors,
            windows: windows
        };
    }

    function setSpecial(monitor: string, name: string) {
        const next = Object.assign({}, specialByMonitor);
        next[monitor] = name;
        specialByMonitor = next;
    }

    function refresh() {
        const prev = primed ? snapshot : null;
        const next = build();
        if (!primed)
            for (const m of Hyprland.monitors.values)
                setSpecial(m.name, m.lastIpcObject?.specialWorkspace?.name ?? "");
        snapshot = next;
        normalWindows = next.windows.filter(w => Strip.isNormalWindow(w, rules));
        primed = true;
        for (const name of Object.keys(next.monitors)) {
            const events = Strip.diffSnapshots(prev, next, name, rules);
            if (events.length > 0)
                triggered(name, events);
        }
    }

    function schedule() {
        Hyprland.refreshToplevels();
        debounce.restart();
    }

    Component.onCompleted: {
        if (!Flags.smoke)
            schedule();
    }

    Timer {
        id: debounce

        interval: Timings.wsDebounce
        onTriggered: root.refresh()
    }

    Connections {
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                const s = Strip.parseActiveSpecial(event.data);
                if (s)
                    root.setSpecial(s.monitor, s.name);
            } else if (Strip.refreshesSnapshot(event.name)) {
                root.schedule();
            }
        }

        target: Flags.smoke ? null : Hyprland
    }
}
