pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../logic/sysStats.mjs" as SysStats

// CPU and RAM usage (0-100) read from /proc; null until a sample is usable.
// Smoke runs never poll.
Singleton {
    id: root

    property var cpu: null
    property var ram: null
    property var lastCpu: null
    property var logicalCpuCount: null
    property var loadAverage: null

    Timer {
        interval: Timings.sysPoll
        repeat: true
        running: !Flags.smoke
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            root.logicalCpuCount = SysStats.parseLogicalCpuCount(text());
            const sample = SysStats.parseCpu(text());
            if (sample === null) {
                console.warn("SysInfo: unreadable /proc/stat");
                return;
            }
            root.cpu = SysStats.cpuPercent(root.lastCpu, sample);
            root.lastCpu = sample;
        }
        onLoadFailed: root.cpu = null
    }

    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: root.loadAverage = SysStats.parseLoadAverage(text())
        onLoadFailed: root.loadAverage = null
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: root.ram = SysStats.parseRam(text())
        onLoadFailed: root.ram = null
    }
}
