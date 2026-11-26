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
    property var lastCpu: null
    property var logicalCpuCount: null
    property var loadAverage: null
    property var memoryDetails: null
    property string logicalCpuCountStatus: "measuring"
    property string loadAverageStatus: "measuring"
    property string memoryDetailsStatus: "measuring"
    readonly property var ram: root.memoryDetails ? Math.round((1 - root.memoryDetails.availableKiB / root.memoryDetails.totalKiB) * 100) : null

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
            root.logicalCpuCountStatus = root.logicalCpuCount === null ? "unavailable" : "available";
            const sample = SysStats.parseCpu(text());
            if (sample === null) {
                console.warn("SysInfo: unreadable /proc/stat");
                return;
            }
            root.cpu = SysStats.cpuPercent(root.lastCpu, sample);
            root.lastCpu = sample;
        }
        onLoadFailed: {
            root.cpu = null;
            root.logicalCpuCount = null;
            root.logicalCpuCountStatus = "unavailable";
        }
    }

    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: {
            root.loadAverage = SysStats.parseLoadAverage(text());
            root.loadAverageStatus = root.loadAverage === null ? "unavailable" : "available";
        }
        onLoadFailed: {
            root.loadAverage = null;
            root.loadAverageStatus = "unavailable";
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            root.memoryDetails = SysStats.parseMemoryDetails(text());
            root.memoryDetailsStatus = root.memoryDetails === null ? "unavailable" : "available";
        }
        onLoadFailed: {
            root.memoryDetails = null;
            root.memoryDetailsStatus = "unavailable";
        }
    }
}
