pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/format.mjs" as Format

// User name and uptime (whole seconds, null until /proc/uptime is readable).
// Smoke runs never poll.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    property var uptime: null

    Timer {
        interval: Timings.uptimePoll
        repeat: true
        running: !Flags.smoke
        triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: {
            root.uptime = Format.parseUptime(text());
            if (root.uptime === null)
                console.warn("OsInfo: unreadable /proc/uptime");
        }
        onLoadFailed: root.uptime = null
    }
}
